local T = require "tests/support/test"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local order = {
    operation = "LUMBER", status = "TRAVEL_TO_STATION",
    workerId = "worker", lastProgressAt = 1000,
}

PNC = {
    WorkTaskProvider = {
        Internal = {
            NeedsFatigueGate = function() return false end,
            PhaseFor = function() return "TRAVEL" end,
        },
    },
    WorkDefinitions = {
        STATUS = {
            CANCELLED = "CANCELLED", COMPLETED = "COMPLETED",
            FAILED = "FAILED", BLOCKED = "BLOCKED",
        },
    },
    WorkFatigueGate = { Check = function() return true end },
    WorkService = {
        Queries = { Get = function() return order end },
    },
    Registry = { Get = function() return {} end },
    Tasking = {
        Internal = {
            ApplyMovementRecovery = function(snapshot)
                snapshot.movement = { active = true, provider = "engine_path" }
                snapshot.watchable = true
                return snapshot
            end,
        },
    },
}

T.load("ProjectHoomans", "server",
    "PNC/Tasking/PNC_WorkTaskProvider_Lease.lua")
local Provider = PNC.WorkTaskProvider

local recovery = Provider.GetRecoveryState({
    sourceRef = "work:lumber", npcId = "worker",
})
T.falsy(recovery.watchable,
    "Lumber travel keeps its lease while PathService repaths")
T.truthy(recovery.movement,
    "Lumber recovery still exposes PathService movement state")

order.operation = "FARMING"
recovery = Provider.GetRecoveryState({
    sourceRef = "work:farming", npcId = "worker",
})
T.truthy(recovery.watchable,
    "non-Lumber travel keeps the normal Tasking recovery policy")

T.finish("pnc_lumber_task_recovery_smoke")
