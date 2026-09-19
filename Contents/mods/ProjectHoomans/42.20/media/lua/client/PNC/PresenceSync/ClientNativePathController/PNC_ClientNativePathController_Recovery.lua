--[[
    PNC Client Native Path Controller: forced traversal and request recovery.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}
PNC.ClientPresenceSync.Internal.NativePathController =
    PNC.ClientPresenceSync.Internal.NativePathController or {}

local Controller = PNC.ClientPresenceSync.Internal.NativePathController
local LiveBodyControl = PNC.LiveBodyControl
local updateVanillaFenceClimb = Controller.UpdateVanillaFenceClimb
local beginMovementLease = Controller.BeginMovementLease
local clearOwnedPath = Controller.ClearOwnedPath
local retryDelay = Controller.RetryDelay
local logState = Controller.LogState
local describeBody = Controller.DescribeBody
local RETRY_BASE_MS = Controller.RETRY_BASE_MS

local function updateForcedTraversal(body, state, key, now)
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
    return false, nil
end

local function recoverFailedPath(
    snapshot,
    body,
    state,
    behavior,
    goal,
    now,
    requestDropped
)
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

Controller.UpdateForcedTraversal = updateForcedTraversal
Controller.RecoverFailedPath = recoverFailedPath
