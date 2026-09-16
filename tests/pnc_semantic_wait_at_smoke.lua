local T = require "tests/support/test"
T.addPackagePaths()

local now = 100
local dirty = 0
local findCalls = 0
local record = { id = "npc:alice", alive = true, x = 0, y = 0, z = 0 }
local campfire = {
    getID = function() return 77 end,
    isCampfire = function() return true end,
}
local recycleBin = {
    getObjectName = function() return "IsoObject" end,
    getSpriteName = function() return "trashcontainers_01_16" end,
}

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
        GetLiveZombie = function() return nil end,
        ForEach = function(callback) callback(record) end,
        MarkDirty = function() dirty = dirty + 1 end,
    },
    NearbyResourceLocator = {
        FindObject = function(_, options)
            findCalls = findCalls + 1
            local isRecycle = tostring(options.cacheKey or "")
                == "semantic_object:recycle_bin"
            local candidate = isRecycle and {
                object = recycleBin,
                key = "recycle_bin@7:0:0#88",
                x = 7, y = 0, z = 0,
            } or {
                object = campfire,
                key = "campfire@5:0:0#77",
                x = 5, y = 0, z = 0,
            }
            return options.accept(candidate) and candidate or nil
        end,
    },
    PathService = {
        AdvanceAbstract = function(owner, x, y, z, stopDistance)
            local dx = x - owner.x
            local dy = y - owner.y
            local distance = math.sqrt((dx * dx) + (dy * dy))
            if distance <= (stopDistance or 0.7) then
                owner.x, owner.y, owner.z = x, y, z
                return true
            end
            local step = math.min(5, distance)
            owner.x = owner.x + (dx / distance) * step
            owner.y = owner.y + (dy / distance) * step
            owner.z = z
            return false
        end,
    },
    BehaviorCommon = {},
    BehaviorMoveIntent = {},
    Semantics = {},
}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticTaskRequest.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticActionPlan.lua"
)
local Plans = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticActionPlanService.lua"
)
Plans.PUMP_INTERVAL_MS = 0
Plans.RECONCILE_INTERVAL_MS = 0

T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticWorldTargetResolver.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanPathProvider.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/ActionPlanProviders/PNC_SemanticActionPlanWaitProvider.lua"
)
local Requests = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticTaskRequestService.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/PNC_SemanticActionPlanTaskHandler.lua"
)

local ir = Semantic.Parser.Parse("Wait at the campfire")
T.equal(ir.action, "WAIT_AT", "campfire command is compositional")
T.equal(ir.target.category, "CAMPFIRE",
    "campfire is a semantic target, not a live object")

local request = PNC.Semantics.TaskRequest.FromIR(ir, {
    requestID = "dialogue:campfire:1",
    rawText = "Wait at the campfire",
    recipient = { id = record.id },
})
request.modifiers.durationMs = 0

local result = Requests.Submit(request, {
    npcID = record.id,
    scope = "single",
})
T.equal(result.accepted, true, "semantic task request is admitted")
T.equal(result.action, "WAIT_AT", "task result preserves the semantic action")
local plan = Plans.GetMutable(record.id)
T.truthy(plan, "accepted request creates an action plan")
T.equal(plan.steps[1].action, "MOVE_TO",
    "the first step reuses the movement provider")
T.equal(plan.steps[2].action, "WAIT",
    "the second step is queued after arrival")

now = 101
Plans.Pump(now)
T.equal(plan.steps[1].state, "ASSIGNED",
    "world target resolution occurs inside the plan pump")
T.equal(plan.steps[1].assignment.targetID, "campfire@5:0:0#77",
    "the nearest campfire becomes a stable primitive assignment")
T.equal(findCalls, 1, "campfire discovery is performed once during resolve")

now = 102
Plans.Pump(now)
now = 103
Plans.Pump(now)
T.equal(plan.steps[1].state, "TRAVEL",
    "movement remains active while the path provider advances")
now = 104
Plans.Pump(now)
T.equal(plan.steps[1].state, "ARRIVED",
    "movement reports arrival before the next task starts")
now = 105
Plans.Pump(now)
T.equal(plan.steps[2].state, "PENDING",
    "arrival advances the ordered queue")

now = 106
Plans.Pump(now)
now = 107
Plans.Pump(now)
now = 108
Plans.Pump(now)
T.equal(plan.steps[2].state, "WAITING",
    "the wait action starts only after movement completes")
now = 109
Plans.Pump(now)
T.equal(plan.state, "COMPLETED", "the queued wait action completes")
T.equal(record.activeBehavior, nil,
    "terminal plan releases semantic behavior ownership")
T.truthy(dirty > 0, "queue transitions persist through the registry seam")

local recycleIR = Semantic.Parser.Parse("stay at the recycle bin")
T.equal(recycleIR.action, "WAIT_AT",
    "named world-object phrase reaches the wait-at action")
local recycleRequest = PNC.Semantics.TaskRequest.FromIR(recycleIR, {
    requestID = "dialogue:recycle-bin:1",
    rawText = "stay at the recycle bin",
    recipient = { id = record.id },
})
recycleRequest.modifiers.durationMs = 0
local recycleResult = Requests.Submit(recycleRequest, {
    npcID = record.id,
    scope = "single",
})
T.equal(recycleResult.accepted, true,
    "named world-object wait request is admitted")
local recyclePlan = Plans.GetMutable(record.id)
T.truthy(recyclePlan, "named world-object request creates a plan")
now = 110
Plans.Pump(now)
T.equal(recyclePlan.steps[1].state, "ASSIGNED",
    "recycle-bin object is resolved during the action-plan pump")
T.equal(recyclePlan.steps[1].assignment.targetID,
    "recycle_bin@7:0:0#88",
    "the logged recycle-bin sprite resolves to a stable target")

T.finish("pnc_semantic_wait_at_smoke")
