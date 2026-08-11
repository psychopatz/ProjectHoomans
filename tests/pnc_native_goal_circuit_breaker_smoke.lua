local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_PathService/PNC_PathService_Lane.lua"

local now = 1000
PNC = {
    Core = { Now = function() return now end },
    Const = {
        ENGINE_PATH_FAILURE_LIMIT = 2,
        ENGINE_PATH_BLOCKED_GOAL_COOLDOWN_MS = 10000,
        ENGINE_PATH_BLOCKED_GOAL_CHANGE_DISTANCE = 1.5,
    },
    PathService = { Internal = {} },
}
PNC.PathService.Internal.Core = PNC.Core

dofile(FILE)

local Internal = PNC.PathService.Internal
local lane = {}
local goal = { x = 10, y = 20, z = 0 }

assert(not Internal.noteNativeGoalFailure(lane, goal, now),
    "first native failure opened the circuit")
assert(Internal.noteNativeGoalFailure(lane, goal, now + 100),
    "second native failure did not open the circuit")
assert(Internal.isNativeGoalBlocked(lane, goal, now + 200),
    "same unreachable goal was not suppressed")
assert(not Internal.isNativeGoalBlocked(
        lane,
        { x = 12, y = 20, z = 0 },
        now + 200
    ),
    "meaningfully changed goal remained suppressed")
assert(lane.nativeFailureCount == 0,
    "changed goal did not reset native failure history")

print("pnc_native_goal_circuit_breaker_smoke: ok")
