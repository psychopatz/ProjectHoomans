local T = require "tests/support/test"

T.addPackagePaths()

local now = 1000
local actionState = "pathfind"
local fenceHandled = false
local fenceResult = "native_fence_wait"
local state = {}
local leaseBegins = 0
local cancelCalls = 0
local resetCalls = 0
local suppressedCalls = 0
local endedLeaseKey
local clearedPath = "unchanged"
local logs = {}
local goal = {
    x = 10,
    y = 0,
    z = 0,
    revision = 9,
    stopDistance = 0.1,
}

local behavior = {
    cancel = function() cancelCalls = cancelCalls + 1 end,
    reset = function() resetCalls = resetCalls + 1 end,
}

local body = {}
function body:getPathFindBehavior2() return behavior end
function body:pathToLocationF() end
function body:getActionStateName() return actionState end
function body:getPath2() return nil end
function body:setPath2(path) clearedPath = path end
function body:getX() return 0 end
function body:getY() return 0 end
function body:getZ() return 0 end

local Controller = {
    CONTROLLER_CHECK_MS = 250,
    STALL_TIMEOUT_MS = 300,
    RETRY_BASE_MS = 500,
    REQUEST_GRACE_MS = 200,
    EnsureState = function() return state end,
    BuildGoal = function() return goal end,
    ClearOwnedPath = function(_, currentState)
        currentState.owned = false
        currentState.leaseKey = nil
        return true
    end,
    UpdatePassageAction = function() return false, nil end,
    UpdateVanillaFenceClimb = function()
        return fenceHandled, fenceResult
    end,
    RequestKey = function() return "test-goal-key" end,
    BeginMovementLease = function() leaseBegins = leaseBegins + 1 end,
    TryNativePassage = function() return false, nil end,
    ShouldProbePassage = function() return false end,
    SubmitPathRequest = function() end,
    RememberProgress = function() end,
    DistanceToGoalSquared = function() return 100 end,
    FinishOwnedPath = function() end,
    NativeActionOwnsMovement = function() return false end,
    RetryDelay = function() return 700 end,
    LogState = function(_, event, detail)
        logs[#logs + 1] = tostring(event) .. " " .. tostring(detail)
    end,
    DescribeBody = function() return " body=recovery-test" end,
}

PNC = {
    Core = {
        IsClientOnly = function() return true end,
        Now = function() return now end,
    },
    LiveBodyControl = {
        SuppressZombieState = function()
            suppressedCalls = suppressedCalls + 1
        end,
        EndNativeMovementLease = function(_, leaseKey)
            endedLeaseKey = leaseKey
        end,
    },
    ClientPresenceSync = {
        Internal = {
            IsLocalZombieController = function() return true end,
            NativePathController = Controller,
        },
    },
}

T.load("ProjectHoomans", "client",
    "PNC/PresenceSync/ClientNativePathController/"
        .. "PNC_ClientNativePathController_Recovery.lua")
T.load("ProjectHoomans", "client",
    "PNC/PresenceSync/ClientNativePathController/"
        .. "PNC_ClientNativePathController_Update.lua")

local Internal = PNC.ClientPresenceSync.Internal

-- Active window traversal keeps the native lease while its action state runs.
state = {
    localController = true,
    nextControllerCheckAt = 2000,
    forcedTraversalUntil = 2500,
    forcedTraversalState = "climbwindow",
}
actionState = "climbwindow"
local handled, reason = Internal.UpdateNativePathController({}, body, now)
T.truthy(handled, "active window traversal was released early")
T.equal(reason, "native_window_climb", "active traversal result changed")
T.equal(leaseBegins, 1, "active traversal did not refresh its movement lease")

-- The existing vanilla-fence updater retains ownership of its active phase.
state = {
    localController = true,
    nextControllerCheckAt = 2000,
    forcedTraversalUntil = 2500,
    forcedTraversalState = "climbfence",
}
fenceHandled = true
fenceResult = "native_fence_vanilla"
handled, reason = Internal.UpdateNativePathController({}, body, now)
T.truthy(handled, "vanilla fence phase was not handled")
T.equal(reason, "native_fence_vanilla", "vanilla fence result changed")
fenceHandled = false

-- A stale forced action clears its lease fields and enters the bounded retry.
now = 1200
state = {
    localController = true,
    nextControllerCheckAt = 2000,
    forcedTraversalUntil = 1100,
    forcedTraversalState = "climbwindow",
}
actionState = "pathfind"
handled, reason = Internal.UpdateNativePathController({}, body, now)
T.truthy(handled, "expired traversal did not remain handled")
T.equal(reason, "native_path_retry_wait", "expired traversal retry state changed")
T.equal(state.forcedTraversalUntil, nil, "expired traversal timer remained set")
T.equal(state.forcedTraversalState, nil, "expired traversal action remained set")
T.equal(state.failed, true, "expired traversal did not enter retry state")
T.equal(state.retryAt, 1700, "expired traversal retry deadline changed")

-- A dropped engine request releases both behavior and the movement lease.
now = 5000
state = {
    localController = true,
    nextControllerCheckAt = 6000,
    owned = true,
    leaseKey = "native-test-lease",
    startedAt = 0,
    lastProgressAt = 5000,
    retries = 2,
}
actionState = "pathfind"
handled, reason = Internal.UpdateNativePathController({}, body, now)
T.truthy(handled, "dropped engine request was not handled")
T.equal(reason, "native_path_failed", "dropped engine request result changed")
T.equal(cancelCalls, 1, "dropped engine request did not cancel behavior")
T.equal(resetCalls, 1, "dropped engine request did not reset behavior")
T.equal(clearedPath, nil, "dropped engine request retained path2")
T.equal(suppressedCalls, 1, "dropped engine request did not suppress zombie state")
T.equal(endedLeaseKey, "native-test-lease", "dropped engine request ended the wrong lease")
T.equal(state.failed, true, "dropped engine request did not mark failure")
T.equal(state.owned, false, "dropped engine request retained path ownership")
T.equal(state.leaseKey, nil, "dropped engine request retained its lease key")
T.equal(state.retryAt, 5700, "dropped engine request retry deadline changed")
T.contains(logs[#logs], "native_controller_failed", "failure diagnostic event")
T.contains(logs[#logs], "engine_request_dropped", "failure diagnostic reason")

T.finish("pnc_client_native_path_recovery_smoke")
