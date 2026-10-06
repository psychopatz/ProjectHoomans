local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local now = 1000
local fallbackCalls = 0
local completeCalls = 0
local warningCalls = 0
local invalidateCalls = 0

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
    EnginePathPlanner = {
        Invalidate = function()
            invalidateCalls = invalidateCalls + 1
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
Internal.tryNativeStallPassage = function()
    return false
end
Internal.applyHoldAnimation = function() end
Internal.isAtGoal = function()
    return false
end
Internal.PROGRESS_TIMEOUT_MS = 100
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
    navigationProvider = "engine_path",
    lastProgressAt = now,
    lastGoalProgressAt = now,
}
local navigation = {}

local handled, state = Internal.recordNativeMove(
    record,
    body,
    lane,
    navigation,
    PNC.EnginePathPlanner,
    now,
    "engine_path_failed",
    body:getX(),
    body:getY(),
    body:getZ()
)

T.truthy(handled and state == "native_repath",
    "follow native failure did not request a native replan")
T.equal(fallbackCalls, 0,
    "follow native failure incorrectly activated fake locomotion")
T.equal(completeCalls, 0,
    "follow native failure incorrectly completed the move as blocked")
T.equal(warningCalls, 0,
    "follow native replan emitted an unbounded warning")
T.equal(invalidateCalls, 1,
    "follow native failure did not invalidate the stale native request")
T.truthy(lane.goal == goal,
    "follow native replan discarded the active owner goal")
T.truthy(lane.ownerMode == "native_backoff",
    "follow native replan did not retain native lane ownership")
T.equal(lane.navigationProvider, "engine_path",
    "follow native replan changed the movement provider")

local stalledLane = {
    goal = goal,
    intentReason = "follow_owner_walk",
    requestedOrder = "follow",
    navigationProvider = "engine_path",
    lastProgressAt = 0,
    lastGoalProgressAt = 0,
}
local stalledHandled, stalledState = Internal.recordNativeMove(
    record,
    body,
    stalledLane,
    navigation,
    PNC.EnginePathPlanner,
    now,
    "native_path_moving",
    body:getX(),
    body:getY(),
    body:getZ()
)
T.truthy(stalledHandled and stalledState == "native_repath",
    "follow native stall did not request a native replan")
T.equal(fallbackCalls, 0,
    "follow native stall incorrectly activated fake locomotion")
T.equal(completeCalls, 0,
    "follow native stall incorrectly completed the move")
T.truthy(stalledLane.ownerMode == "native_backoff",
    "follow native stall did not retain native lane ownership")

T.finish("pnc_follow_native_failure_smoke")
