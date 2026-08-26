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
local steeringCalls = 0

PNC = {
    Const = {},
    Core = { Now = function() return now end },
    PathService = { Internal = {} },
    EnginePathPlanner = {
        Invalidate = function(_, reason)
            invalidations[#invalidations + 1] = reason
            navigation.nativeActive = false
        end,
        GetSteeringTarget = function()
            steeringCalls = steeringCalls + 1
        end,
        Pump = function()
            nativePumpCalls = nativePumpCalls + 1
            return true, "native_behavior_pending"
        end,
    },
}

local Internal = PNC.PathService.Internal
Internal.Core = {
    Now = function() return now end,
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
Internal.hasClosedPassageToward = function() return false end
Internal.applyHoldAnimation = function() end

T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua")

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

lane.traversalAction = nil
attackActive = false
navigation.nativeActive = false
handled, state = PNC.PathService.Pump(record, body, "ownership_test")
T.truthy(handled and state == "native_waiting",
    "inactive native lane fell through to fake locomotion")
T.equal(steeringCalls, 1,
    "inactive native lane did not request steering exactly once")
T.equal(activeMoveCalls, 1,
    "native waiting lane invoked fake locomotion")

T.finish("pnc_path_service_motion_ownership_smoke")
