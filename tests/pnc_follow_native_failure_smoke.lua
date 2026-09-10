local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
local fallbackCalls = 0
local completeCalls = 0
local warningCalls = 0

PNC = {
    Core = {
        Now = function() return now end,
        Distance = function(x1, y1, x2, y2)
            local dx = (tonumber(x1) or 0) - (tonumber(x2) or 0)
            local dy = (tonumber(y1) or 0) - (tonumber(y2) or 0)
            return math.sqrt((dx * dx) + (dy * dy))
        end,
    },
    Const = {
        ORDER_FOLLOW = "follow",
        ENGINE_PATH_FALLBACK_COOLDOWN_MS = 5000,
    },
    NavigationRouter = {
        ActivateFallback = function()
            fallbackCalls = fallbackCalls + 1
            return true
        end,
    },
    PathService = { Internal = {} },
}

local Internal = PNC.PathService.Internal
Internal.Core = PNC.Core
Internal.clearNativeGoalBlock = function(lane)
    lane.nativeFailureCount = 0
end
Internal.describeGoal = function(goal)
    return tostring(goal.x) .. "," .. tostring(goal.y)
end
Internal.logMoveWarning = function()
    warningCalls = warningCalls + 1
end
Internal.noteNativeGoalFailure = function()
    error("follow native failure must recover before the goal circuit breaker")
end
Internal.completeMove = function()
    completeCalls = completeCalls + 1
    return true, "blocked"
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionNativeProgress.lua"
)

local body = {
    getX = function() return 10.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
}
local goal = { x = 4.5, y = 10.5, z = 0 }
local record = { runtime = {} }
local lane = {
    goal = goal,
    intentReason = "follow_owner_walk",
    requestedOrder = "follow",
    lastProgressAt = now,
    lastGoalProgressAt = now,
}
local navigation = {}

local handled, state = Internal.recordNativeMove(
    record,
    body,
    lane,
    navigation,
    {},
    now,
    "engine_path_failed",
    body:getX(),
    body:getY(),
    body:getZ()
)

T.truthy(handled and state == "native_path_fallback",
    "follow native failure did not activate movement fallback")
T.equal(fallbackCalls, 1,
    "follow native failure did not call the navigation fallback")
T.equal(completeCalls, 0,
    "follow native failure incorrectly completed the move as blocked")
T.equal(warningCalls, 1,
    "follow native fallback was not diagnosed")
T.truthy(lane.goal == goal,
    "follow native fallback discarded the active owner goal")
T.truthy(lane.ownerMode == "fake_locomotion",
    "follow native fallback did not transfer lane ownership")

T.finish("pnc_follow_native_failure_smoke")
