--[[
    PNC Client Native Path Controller: path request and retry loop
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
Internal.NativePathController =
    Internal.NativePathController or {}
local Controller = Internal.NativePathController
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local ensureState = Controller.EnsureState
local buildGoal = Controller.BuildGoal
local clearOwnedPath = Controller.ClearOwnedPath
local updateWindowSmash = Controller.UpdateWindowSmash
local updateVanillaFenceClimb = Controller.UpdateVanillaFenceClimb
local requestKey = Controller.RequestKey
local beginMovementLease = Controller.BeginMovementLease
local tryNativePassage = Controller.TryNativePassage
local shouldProbePassage = Controller.ShouldProbePassage
local submitPathRequest = Controller.SubmitPathRequest
local rememberProgress = Controller.RememberProgress
local distanceToGoalSquared = Controller.DistanceToGoalSquared
local finishOwnedPath = Controller.FinishOwnedPath
local nativeActionOwnsMovement =
    Controller.NativeActionOwnsMovement
local retryDelay = Controller.RetryDelay
local logState = Controller.LogState
local describeBody = Controller.DescribeBody
local CONTROLLER_CHECK_MS = Controller.CONTROLLER_CHECK_MS
local STALL_TIMEOUT_MS = Controller.STALL_TIMEOUT_MS
local RETRY_BASE_MS = Controller.RETRY_BASE_MS
local REQUEST_GRACE_MS = Controller.REQUEST_GRACE_MS

function Internal.UpdateNativePathController(
    snapshot,
    body,
    now
)
    if not body
        or not Core
        or not Core.IsClientOnly
        or Core.IsClientOnly() ~= true
    then
        return false, "not_mp_client"
    end
    now = tonumber(now)
        or (Core.Now and Core.Now() or 0)
    local state = ensureState(body)
    state.snapshot = snapshot
    state.lastSeenAt = now
    if state.passageAction then
        return updateWindowSmash(body, state, now)
    end
    local goal = buildGoal(snapshot, body)
    if not goal then
        clearOwnedPath(body, state)
        return false, "native_goal_inactive"
    end
    if state.localController == nil
        or now >= (
            tonumber(state.nextControllerCheckAt) or 0
        )
    then
        state.localController =
            Internal.IsLocalZombieController(body)
        state.nextControllerCheckAt =
            now + CONTROLLER_CHECK_MS
    end
    if state.localController ~= true then
        local wasOwned = state.owned == true
        if wasOwned or state.leaseKey ~= nil then
            clearOwnedPath(body, state)
        end
        if wasOwned then
            logState(
                snapshot,
                "native_controller_release",
                "reason=nearest_client_changed"
            )
        end
        return false, "native_observer"
    end

    local behavior = body.getPathFindBehavior2
        and body:getPathFindBehavior2() or nil
    if not behavior or not body.pathToLocationF then
        if state.owned == true or state.leaseKey ~= nil then
            clearOwnedPath(body, state)
        end
        return false, "native_path_api_unavailable"
    end

    local key = requestKey(snapshot, goal)
    if state.forcedTraversalUntil then
        if state.forcedTraversalState == "climbfence"
            and updateVanillaFenceClimb
        then
            local fenceHandled
            local fenceState
            fenceHandled, fenceState = updateVanillaFenceClimb(
                body, state, now
            )
            if fenceHandled then
                return true, fenceState
            end
        end
        local forcedState = state.forcedTraversalState
            or "climbwindow"
        local actionState = body.getActionStateName
            and string.lower(tostring(
                body:getActionStateName() or ""
            )) or ""
        if actionState == forcedState
            and now < state.forcedTraversalUntil
        then
            beginMovementLease(body, state, key, now)
            return true, forcedState == "climbwindow"
                and "native_window_climb"
                or "native_traversal"
        end
        if actionState == forcedState
            and LiveBodyControl
            and LiveBodyControl.SuppressZombieState
        then
            LiveBodyControl.SuppressZombieState(body, state, now)
        end
        state.forcedTraversalUntil = nil
        state.forcedTraversalState = nil
        state.forcedTraversalAction = nil
        state.requestKey = nil
        state.failed = true
        state.retryAt = now + RETRY_BASE_MS
    end
    local passageHandled
    local passageState
    if shouldProbePassage
        and shouldProbePassage(body, state, now)
    then
        passageHandled, passageState = tryNativePassage(
            snapshot,
            body,
            state,
            goal,
            now
        )
    end
    if passageHandled then
        return true, passageState
    end
    submitPathRequest(
        snapshot,
        body,
        state,
        goal,
        key,
        behavior,
        now
    )
    if state.completed == true or state.failed == true then
        return true, state.completed
            and "native_path_succeeded"
            or "native_path_retry_wait"
    end

    if state.owned == true then
        beginMovementLease(body, state, key, now)
    end

    rememberProgress(body, state, now)
    if distanceToGoalSquared(body, goal)
        <= goal.stopDistance * goal.stopDistance
    then
        finishOwnedPath(body, state, behavior)
        logState(
            snapshot,
            "native_controller_complete",
            "revision=" .. tostring(goal.revision)
        )
        return true, "native_path_succeeded"
    end
    local hasPath = body.getPath2
        and body:getPath2() ~= nil or false
    local requestDropped = state.owned == true
        and now - (tonumber(state.startedAt) or now)
            >= REQUEST_GRACE_MS
        and not hasPath
        and not nativeActionOwnsMovement(body)
    if requestDropped
        or now - (tonumber(state.lastProgressAt) or now)
            >= STALL_TIMEOUT_MS
    then
        if behavior.cancel then behavior:cancel() end
        if behavior.reset then behavior:reset() end
        if body.setPath2 then body:setPath2(nil) end
        if LiveBodyControl
            and LiveBodyControl.SuppressZombieState
        then
            LiveBodyControl.SuppressZombieState(body, state, now)
        end
        if LiveBodyControl
            and LiveBodyControl.EndNativeMovementLease
        then
            LiveBodyControl.EndNativeMovementLease(
                body,
                state.leaseKey
            )
        end
        state.failed = true
        state.owned = false
        state.leaseKey = nil
        state.retryAt = now + retryDelay(state)
        logState(
            snapshot,
            "native_controller_failed",
            "reason=" .. tostring(
                requestDropped
                    and "engine_request_dropped"
                    or "movement_stalled"
            )
                .. " revision=" .. tostring(goal.revision)
                .. " retry=" .. tostring(state.retries)
                .. describeBody(body)
        )
        return true, "native_path_failed"
    end
    return true, "native_path_moving"
end
