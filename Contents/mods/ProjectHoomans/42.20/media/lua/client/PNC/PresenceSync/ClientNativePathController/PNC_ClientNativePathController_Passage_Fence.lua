--[[
    PNC Native Passage: fence retry routing and vanilla climb recovery.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Controller = Sync.Internal.NativePathController
local Passage = Controller.PassageInternal
local Fence = Passage.FenceInternal

local TraversalQuery = PNC.TraversalQuery
local LiveBodyControl = PNC.LiveBodyControl
local clearOwnedPath = Controller.ClearOwnedPath
local beginMovementLease = Controller.BeginMovementLease

local function updateVanillaFenceClimb(body, state, now)
    local action = state and state.forcedTraversalAction or nil
    local actionState
    local crossed
    if not action then return false, nil end
    actionState = Fence.ActionStateName(body)
    crossed = Fence.Crossed(body, action)
    if crossed then
        clearOwnedPath(body, state)
        state.forcedTraversalAction = nil
        state.forcedTraversalState = nil
        state.forcedTraversalUntil = nil
        state.requestKey = nil
        state.fenceCooldownKey = action.fenceKey
        state.fenceCooldownUntil = now + Fence.Policy.CooldownMs
        state.failed = true
        state.retryAt = now
        return true, "native_fence_vanilla_crossed"
    end
    if actionState == "climbfence"
        and now < (tonumber(action.finishAt) or now)
    then
        beginMovementLease(body, state, action.key, now)
        return true, "native_fence_vanilla"
    end
    if now < (tonumber(action.startGraceUntil) or now) then
        beginMovementLease(body, state, action.key, now)
        return true, "native_fence_vanilla_starting"
    end
    if actionState == "climbfence"
        and LiveBodyControl
        and LiveBodyControl.SuppressZombieState
    then
        LiveBodyControl.SuppressZombieState(body, state, now)
    end
    clearOwnedPath(body, state)
    state.forcedTraversalAction = nil
    state.forcedTraversalState = nil
    state.forcedTraversalUntil = nil
    state.requestKey = nil
    state.fenceRetryKey = action.fenceKey
    state.fenceRetryAt = now + Fence.Policy.RetryBackoffMs
    state.failed = true
    state.retryAt = state.fenceRetryAt
    return true, "native_fence_vanilla_same_side"
end

local function tryFence(snapshot, body, state, passage, object, now)
    if not TraversalQuery.IsFence
        or TraversalQuery.IsFence(object) ~= true
    then
        return false, nil, nil
    end
    local key = Fence.Key(object, passage)
    if state.fenceRetryKey == key
        and now < (tonumber(state.fenceRetryAt) or 0)
    then
        clearOwnedPath(body, state)
        return true, true, "native_fence_retry_wait"
    end
    if state.fenceRetryKey == key then
        state.fenceRetryKey = nil
        state.fenceRetryAt = nil
    end
    if state.fenceCooldownKey == key
        and now < (tonumber(state.fenceCooldownUntil) or 0)
    then
        clearOwnedPath(body, state)
        return true, true, "native_fence_cooldown"
    end
    if state.fenceCooldownKey == key then
        state.fenceCooldownKey = nil
        state.fenceCooldownUntil = nil
    end
    local handled, reason = Fence.StartClimb(
        snapshot, body, state, passage, object, now
    )
    return true, handled, reason
end

Passage.TryFence = tryFence
Controller.UpdateVanillaFenceClimb = updateVanillaFenceClimb
