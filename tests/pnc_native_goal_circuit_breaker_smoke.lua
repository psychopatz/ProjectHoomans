local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
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

T.load(FILE)

local Internal = PNC.PathService.Internal
local lane = {}
local goal = { x = 10, y = 20, z = 0 }

T.truthy(not Internal.noteNativeGoalFailure(lane, goal, now),
    "first native failure opened the circuit")
T.truthy(Internal.noteNativeGoalFailure(lane, goal, now + 100),
    "second native failure did not open the circuit")
T.truthy(Internal.isNativeGoalBlocked(lane, goal, now + 200),
    "same unreachable goal was not suppressed")
T.truthy(not Internal.isNativeGoalBlocked(
        lane,
        { x = 12, y = 20, z = 0 },
        now + 200
    ),
    "meaningfully changed goal remained suppressed")
T.truthy(lane.nativeFailureCount == 0,
    "changed goal did not reset native failure history")

-- Follow goals need the same one-retry grace as ordinary engine routes. A
-- transient single-player handoff failure must not immediately block a
-- companion's route.
lane = { intentReason = "follow_owner_walk" }
T.truthy(not Internal.noteNativeGoalFailure(lane, goal, now),
    "follow goal blocked after its first native failure")
T.truthy(Internal.noteNativeGoalFailure(lane, goal, now + 100),
    "follow goal did not block after its retry failed")
T.finish("pnc_native_goal_circuit_breaker_smoke")
