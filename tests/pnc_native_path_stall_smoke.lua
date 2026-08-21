local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local now = 1400
local invalidations = 0
local interactions = 0
local lane = {
    phase = "active",
    navigationProvider = "engine_path",
    goal = { x = 5.5, y = 0.5, z = 0, mode = "walk" },
    stopDistance = 0.45,
    bestGoalDistance = 5,
    lastGoalProgressAt = 1000,
    lastProgressAt = 1000,
    visualMovingUntil = 0,
}
local navigation = {
    provider = "engine_path",
    nativeActive = true,
}
local record = { id = "native-stall", runtime = {
    pathing = lane,
    localNavigation = navigation,
} }
local body = {
    getX = function() return 0.5 end,
    getY = function() return 0.5 end,
    getZ = function() return 0 end,
}

PNC = {
    Core = { Now = function() return now end },
    PathService = { Internal = {} },
    EnginePathPlanner = {
        Pump = function() return true, "native_behavior_pending" end,
        Invalidate = function(_, reason)
            invalidations = invalidations + 1
            T.equal(reason, "native_stall_door_open",
                "stall recovery invalidation reason")
            navigation.nativeActive = false
            return true
        end,
        Internal = {
            GetNativeTraversalState = function() return nil end,
        },
    },
}

local Internal = PNC.PathService.Internal
Internal.Core = {
    Now = function() return now end,
    Distance = function(x1, y1, x2, y2)
        local dx = x2 - x1
        local dy = y2 - y1
        return math.sqrt(dx * dx + dy * dy)
    end,
}
Internal.INTERACTION_STALL_MS = 260
Internal.PROGRESS_TIMEOUT_MS = 2200
Internal.LOCOMOTION_VISUAL_LEASE_MS = 120
Internal.ensureMoveLane = function() return lane end
Internal.repairInvalidBodyPosition = function() return false end
Internal.applyCombatFacing = function() end
Internal.hasActiveAttack = function() return false end
Internal.consumeMoveIntent = function() return nil end
Internal.isDoorCollision = function() return false end
Internal.hasClosedPassageToward = function() return false end
Internal.refreshResolvedLocomotion = function() return "walk" end
Internal.setWalkAnim = function() end
Internal.syncRecordPosition = function() end
Internal.isAtGoal = function() return false end
Internal.describeGoal = function() return "5.5,0.5,0" end
Internal.logMoveWarning = function() end
Internal.logMoveDebug = function() end
Internal.tryDoorOrWindowInteraction = function()
    interactions = interactions + 1
    return true, "door_open"
end
Internal.clearBlockedStep = function() end

T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua")
local PathService = PNC.PathService

local handled, state = PathService.Pump(record, body, "test")
T.truthy(handled, "native stall remains handled during recovery")
T.equal(state, "door_open", "native stall opens the blocking door")
T.equal(interactions, 1, "native stall invokes passage recovery")
T.equal(invalidations, 1, "opened door invalidates the stale native route")
T.equal(lane.lastGoalProgressAt, now,
    "door recovery resets the goal-progress watchdog")

T.finish("pnc_native_path_stall_smoke")
