local T = require "tests/support/test"
T.addPackagePaths()

local now = 100
local dirty = 0
local record = { id = "npc:alice", alive = true }

PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
}
PNC = {
    Core = {
        IsAuthority = function() return true end,
        Now = function() return now end,
    },
    Registry = {
        Get = function(id)
            return tostring(id or "") == record.id and record or nil
        end,
        ForEach = function(callback) callback(record) end,
        MarkDirty = function() dirty = dirty + 1 end,
    },
    Semantics = {},
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticActionPlan.lua"
)
local Service = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticActionPlanService.lua"
)
local Plan = PNC.Semantics.ActionPlan

Service.PUMP_INTERVAL_MS = 0
Service.RECONCILE_INTERVAL_MS = 0

local resolveCalls = 0
local startCalls = 0
local tickCalls = 0
local registered, provider = Service.RegisterProvider("guard", {
    Resolve = function(plan, step, owner)
        resolveCalls = resolveCalls + 1
        T.equal(owner, record, "provider receives authoritative record")
        return { kind = "world_point", x = 10, y = 20, z = 0 }
    end,
    Start = function(_, step)
        startCalls = startCalls + 1
        T.equal(step.assignment.kind, "world_point",
            "provider receives the bounded assignment")
        return { state = "TRAVEL", leaseID = "plan-lease:1" }
    end,
    Tick = function(_, step)
        tickCalls = tickCalls + 1
        if step.state == "TRAVEL" then return { state = "ARRIVED" } end
        return { complete = true, result = { guarded = true } }
    end,
})
T.equal(registered, true, "provider registration succeeds")
T.equal(provider.action, nil, "provider remains a plain authored table")

local submitted, plan = Service.Submit({
    planID = "plan:guard",
    npcID = record.id,
    source = "semantic_dialogue",
    rawText = "wait at the campfire",
    confidence = 0.96,
    steps = {
        { id = "step:guard", action = "GUARD" },
    },
})
T.equal(submitted, true, "authority accepts a normalized action plan")
T.equal(plan.state, "RUNNING", "submitted plan starts running")
T.equal(plan.steps[1].state, "RESOLVING", "first step starts resolving")
T.equal(record.semanticActionPlan, plan,
    "the authoritative record owns the active plan")
local owner = Service.GetExecutionOwner(record)
T.equal(owner.action, "GUARD", "the plan exposes its current owner")
T.equal(Service.ShouldYieldBehavior(record), true,
    "normal behavior yields while a plan step is active")

now = 101
Service.Pump(now)
T.equal(plan.steps[1].state, "ASSIGNED", "resolve advances exactly once")
T.equal(resolveCalls, 1, "resolve callback runs once")

now = 102
Service.Pump(now)
T.equal(plan.steps[1].state, "TRAVEL", "start hands movement to provider")
T.equal(startCalls, 1, "start callback runs once")

now = 103
Service.Pump(now)
T.equal(plan.steps[1].state, "ARRIVED", "provider arrival is semantic state")

now = 104
Service.Pump(now)
T.equal(plan.state, "COMPLETED", "completed step completes the plan")
T.equal(plan.currentStep, 2, "advance moves beyond the final step")
T.equal(tickCalls, 2, "provider tick owns travel and arrival completion")
T.equal(Service.Queries.ActiveCount(), 0,
    "terminal plans leave the bounded active index")
T.equal(Service.GetExecutionOwner(record), nil,
    "terminal plans release behavior ownership")
T.truthy(dirty > 0, "plan transitions mark the authoritative record dirty")

local snapshot = Service.Get(record.id)
T.truthy(snapshot, "query returns a plan snapshot")
snapshot.state = "FAILED"
T.equal(plan.state, "COMPLETED", "queries cannot mutate live plan state")

Service.UnregisterProvider("GUARD")
local blocked, blockedPlan = Service.Submit({
    planID = "plan:missing",
    npcID = record.id,
    steps = { { action = "CAMPFIRE" } },
})
T.equal(blocked, true, "a later plan can replace a terminal plan")
now = 105
Service.Pump(now)
now = 106
Service.Pump(now)
T.equal(blockedPlan.steps[1].state, "BLOCKED",
    "missing providers fail closed as a retryable block")
T.equal(Service.Retry(record.id), true, "blocked plans can be retried")
T.equal(blockedPlan.steps[1].state, "RESOLVING",
    "retry returns the step to resolution")

T.finish("pnc_semantic_action_plan_service_smoke")
