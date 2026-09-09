local T = require "tests/support/test"

T.addPackagePaths()

local elapsedCalls = 0
local registeredTick

PNC = {
    Core = {
        Now = function() return 1000 end,
        Distance = function() return 0 end,
    },
    WorkDefinitions = {
        JOB_BY_OPERATION = { CORPSE_HAUL = "CorpseHaul" },
        MANUAL_PROGRESS = { CORPSE_HAUL = true },
    },
    WorkService = {
        Commands = {
            AddElapsed = function()
                elapsedCalls = elapsedCalls + 1
                return true
            end,
        },
    },
    OrderSystem = {
        RegisterNormalizer = function() end,
    },
    JobSystem = {
        RegisterOrder = function() end,
    },
    BehaviorRegistry = {
        Register = function(_, callback) registeredTick = callback end,
    },
    BehaviorCommon = {
        ClearCombatTarget = function() end,
        MoveRecord = function() end,
        HaltMovement = function() end,
    },
}

T.load("ProjectHoomans", "shared", "PNC/Core/Production/PNC_WorkBehavior.lua")

local record = {
    id = "npc:manual-progress",
    x = 10, y = 10, z = 0,
    runtime = {},
    orderSpec = {
        kind = "production_work", operation = "CORPSE_HAUL",
        workOrderId = "work:manual-progress",
        phase = "SOURCE_APPROACH", x = 10, y = 10, z = 0,
    },
}

T.truthy(registeredTick, "work behavior registers its tick function")
T.truthy(registeredTick(record),
    "manual-progress behavior continues the operation lane")
T.equal(elapsedCalls, 0,
    "manual-progress operation does not call generic AddElapsed")

T.finish("pnc_work_behavior_progress_smoke")
