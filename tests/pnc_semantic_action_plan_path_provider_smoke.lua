local T = require "tests/support/test"
T.addPackagePaths()

local now = 100
local records = {}
local bodies = {}
local resetCalls = 0
local moveCalls = 0

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
        Get = function(id) return records[tostring(id or "")] end,
        ForEach = function(callback)
            for _, record in pairs(records) do callback(record) end
        end,
        GetLiveZombie = function(id) return bodies[tostring(id or "")] end,
        MarkDirty = function() end,
    },
    PathService = {
        AdvanceAbstract = function(record, x, y, z, stopDistance)
            local dx = x - record.x
            local dy = y - record.y
            local distance = math.sqrt((dx * dx) + (dy * dy))
            if distance <= (stopDistance or 0.7) then
                record.x, record.y, record.z = x, y, z
                return true
            end
            local step = math.min(5, distance)
            record.x = record.x + (dx / distance) * step
            record.y = record.y + (dy / distance) * step
            record.z = z
            return false
        end,
        GetMovementRecoveryState = function()
            return { active = true, phase = "active" }
        end,
        Commands = {
            Reset = function()
                resetCalls = resetCalls + 1
                return true
            end,
        },
    },
    BehaviorCommon = {
        MoveRecord = function(record, body, x, y, z)
            moveCalls = moveCalls + 1
            record.runtime = record.runtime or {}
            record.runtime.moveIntent = {
                kind = "move", x = x, y = y, z = z,
            }
            body.targetX, body.targetY, body.targetZ = x, y, z
            return true, "move_intent"
        end,
    },
    BehaviorMoveIntent = {},
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

Service.PUMP_INTERVAL_MS = 0
Service.RECONCILE_INTERVAL_MS = 0

local abstract = { id = "npc:abstract", alive = true, x = 0, y = 0, z = 0 }
records[abstract.id] = abstract
local accepted, plan = Service.Submit({
    planID = "plan:abstract_move",
    npcID = abstract.id,
    steps = {
        {
            id = "step:move",
            action = "MOVE_TO",
            parameters = {
                target = { kind = "world_point", id = "campfire:1",
                    x = 10, y = 0, z = 0 },
            },
        },
    },
})
T.equal(accepted, true, "abstract move plan submits")
now = 101
Service.Pump(now)
T.equal(plan.steps[1].state, "ASSIGNED",
    "the path provider resolves a bounded coordinate assignment")
now = 102
Service.Pump(now)
T.equal(plan.steps[1].state, "TRAVEL",
    "abstract movement starts as a travel step")
for _ = 1, 4 do
    now = now + 1
    Service.Pump(now)
end
T.equal(plan.state, "COMPLETED",
    "abstract movement advances the plan after arrival")
T.equal(abstract.x, 10, "abstract movement reaches the target")

local live = { id = "npc:live", alive = true, x = 0, y = 0, z = 0,
    runtime = {} }
local body = {
    x = 0, y = 0, z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
}
records[live.id] = live
bodies[live.id] = body
local liveAccepted, livePlan = Service.Submit({
    planID = "plan:live_move",
    npcID = live.id,
    steps = {
        {
            id = "step:move",
            action = "MOVE_TO",
            parameters = { target = { x = 4, y = 5, z = 0 } },
        },
    },
})
T.equal(liveAccepted, true, "live move plan submits")
now = now + 1
Service.Pump(now)
now = now + 1
Service.Pump(now)
T.equal(livePlan.steps[1].state, "TRAVEL",
    "live movement starts through the provider")
T.equal(moveCalls, 1,
    "live movement delegates to the existing behavior/path seam")
body.x, body.y, body.z = 4, 5, 0
now = now + 1
Service.Pump(now)
now = now + 1
Service.Pump(now)
T.equal(livePlan.state, "COMPLETED",
    "live arrival completes the movement step")
T.equal(resetCalls, 1, "arrival releases the path lane")

local player = {
    x = 20, y = 5, z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
}
local dynamicAccepted, dynamicPlan = Service.Submit({
    planID = "plan:dynamic_player",
    npcID = live.id,
    steps = {
        {
            id = "step:follow_player",
            action = "MOVE_TO",
            parameters = {
                target = {
                    kind = "player",
                    targetID = "player:1",
                    dynamic = true,
                },
            },
        },
    },
}, { player = player })
T.equal(dynamicAccepted, true, "dynamic target plan submits")
T.equal(Service.GetRuntimeContext(dynamicPlan.planID).player, player,
    "live target context stays outside the persisted plan")
now = now + 1
Service.Pump(now)
T.equal(dynamicPlan.steps[1].assignment.x, 20,
    "dynamic player target resolves from runtime context")
now = now + 1
Service.Pump(now)
T.equal(body.targetX, 20,
    "dynamic target starts through the existing movement lane")
player.x = 22
now = now + 1
Service.Pump(now)
T.equal(body.targetX, 22,
    "movement target refreshes after the player moves")
body.x, body.y, body.z = 22, 5, 0
now = now + 1
Service.Pump(now)
now = now + 1
Service.Pump(now)
T.equal(dynamicPlan.state, "COMPLETED",
    "dynamic target movement completes after arrival")
T.equal(Service.GetRuntimeContext(dynamicPlan.planID), nil,
    "terminal plans release live target context")

T.finish("pnc_semantic_action_plan_path_provider_smoke")
