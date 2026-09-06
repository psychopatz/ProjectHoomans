local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local now = 5000
local lane = {
    phase = "active",
    navigationProvider = "engine_path",
    goal = { x = 8.5, y = 2.5, z = 0, mode = "walk" },
    visualMovingUntil = 0,
}
local navigation = {
    provider = "engine_path",
    nativeActive = true,
}
local record = {
    runtime = {
        pathing = lane,
        localNavigation = navigation,
    },
}
local body = {
    getX = function() return 1.5 end,
    getY = function() return 2.5 end,
    getZ = function() return 0 end,
}
local attackActive = true
local invalidations = {}
local intentConsumptions = 0
local activeMoveCalls = 0
local nativePumpCalls = 0
local nativePumpSource
local steeringCalls = 0
local passageProbeCalls = 0

PNC = {
    Const = {},
    Core = { Now = function() return now end },
    LiveBodyControl = {
        IsMultiplayer = function() return false end,
    },
    PathService = { Internal = {} },
    EnginePathPlanner = {
        Invalidate = function(_, reason)
            invalidations[#invalidations + 1] = reason
            navigation.nativeActive = false
        end,
        GetSteeringTarget = function()
            steeringCalls = steeringCalls + 1
        end,
        Pump = function(_, _, source)
            nativePumpCalls = nativePumpCalls + 1
            nativePumpSource = source
            return true, "native_behavior_pending"
        end,
    },
}

local Internal = PNC.PathService.Internal
Internal.LiveBodyControl = PNC.LiveBodyControl
Internal.Core = {
    Now = function() return now end,
    Distance = function(x1, y1, x2, y2)
        local dx = x2 - x1
        local dy = y2 - y1
        return math.sqrt(dx * dx + dy * dy)
    end,
}
Internal.ensureMoveLane = function() return lane end
Internal.repairInvalidBodyPosition = function() return false end
Internal.applyCombatFacing = function() end
Internal.hasActiveAttack = function() return attackActive end
Internal.consumeMoveIntent = function()
    intentConsumptions = intentConsumptions + 1
    return nil
end
Internal.isDoorCollision = function() return false end
Internal.hasClosedPassageToward = function()
    passageProbeCalls = passageProbeCalls + 1
    return false
end
Internal.applyHoldAnimation = function() end
Internal.tryNativeAdjacentPassage = function() return false end
Internal.refreshResolvedLocomotion = function() return "walk" end
Internal.setWalkAnim = function() end
Internal.recordNativeMove = function(_, _, _, _, _, _, nativeState)
    return true, nativeState
end

T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua")

-- The loaded progress/passage providers define their production helpers;
-- keep this ownership test focused on the pump boundary itself.
Internal.tryNativeAdjacentPassage = function() return false end
Internal.recordNativeMove = function(_, _, _, _, _, _, nativeState)
    return true, nativeState
end

local handled
local state
handled, state = PNC.PathService.Pump(record, body, "ownership_test")
T.truthy(handled and state == "attack_active",
    "attack animation lease did not retain first ownership")
T.equal(intentConsumptions, 0,
    "movement intent was consumed during the attack lease")
T.equal(invalidations[1], "combat_attack_lease",
    "attack lease did not invalidate native movement")

-- A traversal must take ownership even if the body still reports an active
-- bump lease from the animation layer.
attackActive = true
navigation.nativeActive = true
lane.traversalAction = { phase = "up" }
Internal.updateActiveMove = function()
    activeMoveCalls = activeMoveCalls + 1
    return true, "fence_climb"
end
handled, state = PNC.PathService.Pump(record, body, "ownership_test")
T.truthy(handled and state == "fence_climb",
    "scripted traversal did not override its own attack-looking bump lease")
T.equal(activeMoveCalls, 1,
    "scripted traversal was not advanced exactly once")
T.equal(nativePumpCalls, 0,
    "native engine advanced while scripted traversal owned motion")
T.equal(passageProbeCalls, 0,
    "ordinary ownership pump performed a proactive passage scan")

lane.traversalAction = nil
attackActive = false
navigation.nativeActive = true
local intentBeforeNative = intentConsumptions
handled, state = PNC.PathService.Pump(record, body, "ownership_test")
T.truthy(handled and state == "native_waiting_for_zombie_update",
    "single-player scheduler advanced the native lane")
T.equal(nativePumpCalls, 0,
    "single-player scheduler pumped the native engine")
T.equal(intentConsumptions, intentBeforeNative + 1,
    "single-player scheduler did not process native movement intent")

-- Once a native intent has been consumed, the scheduler should yield before
-- running the same active-route preamble again. A new revision still remains
-- eligible for immediate consumption in the production path.
record.runtime.moveIntent = { kind = "move", revision = 1 }
lane.intentRevision = 1
local stableIntentCount = intentConsumptions
handled, state = PNC.PathService.Pump(record, body, "ownership_test")
T.truthy(handled and state == "native_waiting_for_zombie_update",
    "single-player native route did not yield after intent consumption")
T.equal(intentConsumptions, stableIntentCount,
    "single-player native route re-consumed a stable intent")

navigation.nativeActive = false
handled, state = PNC.PathService.Pump(record, body, "ownership_test")
T.truthy(handled and state == "native_waiting",
    "inactive native lane fell through to fake locomotion")
T.equal(steeringCalls, 1,
    "inactive native lane did not request steering exactly once")
T.equal(activeMoveCalls, 1,
    "native waiting lane invoked fake locomotion")
T.equal(passageProbeCalls, 0,
    "native waiting lane performed a proactive passage scan")

-- Multiplayer native movement is pumped by PathService. The planner must
-- receive the caller label as its third argument; passing the lane table here
-- hides the actual pump source and makes duplicate-pump diagnosis unreliable.
PNC.LiveBodyControl.IsMultiplayer = function() return true end
navigation.nativeActive = true
handled, state = PNC.PathService.Pump(record, body, "ownership_test")
T.truthy(handled and state == "native_behavior_pending",
    "multiplayer native lane did not reach the planner")
T.equal(nativePumpSource, "ownership_test",
    "native planner received the route lane instead of the caller label")

T.finish("pnc_path_service_motion_ownership_smoke")
