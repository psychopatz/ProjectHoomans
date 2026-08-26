--[[
    PNC Client Native Path Controller: ownership state and movement leases
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
local LiveBodyControl = PNC.LiveBodyControl
local MOVEMENT_LEASE_MS = Controller.MOVEMENT_LEASE_MS
local RETRY_BASE_MS = Controller.RETRY_BASE_MS
local RETRY_MAX_MS = Controller.RETRY_MAX_MS

Sync.NativePathStateByBody =
    Sync.NativePathStateByBody or {}

local function ensureState(body)
    local state = Sync.NativePathStateByBody[body]
    if not state then
        state = {
            owned = false,
            retries = 0,
            retryAt = 0,
        }
        Sync.NativePathStateByBody[body] = state
    end
    return state
end

local function playerID(player)
    if player and player.getOnlineID then
        return tonumber(player:getOnlineID())
    end
    return nil
end

function Internal.IsLocalZombieController(body)
    local localPlayer = getSpecificPlayer
        and getSpecificPlayer(0) or nil
    local players = getOnlinePlayers
        and getOnlinePlayers() or nil
    if not localPlayer then
        return false
    end
    if not players or not players.size or players:size() <= 0 then
        return true
    end

    local nearest
    local nearestDistance = math.huge
    local i
    local player
    local dx
    local dy
    local distance
    for i = 0, players:size() - 1 do
        player = players:get(i)
        if player then
            dx = body:getX() - player:getX()
            dy = body:getY() - player:getY()
            distance = (dx * dx) + (dy * dy)
            if distance < nearestDistance then
                nearestDistance = distance
                nearest = player
            end
        end
    end
    if nearest == localPlayer then
        return true
    end
    return playerID(nearest) ~= nil
        and playerID(nearest) == playerID(localPlayer)
end

local function clearOwnedPath(body, state)
    local behavior
    local leaseKey
    if not body or not state then
        return
    end
    leaseKey = state.leaseKey
    if state.owned == true then
        behavior = body.getPathFindBehavior2
            and body:getPathFindBehavior2() or nil
        if behavior then
            if behavior.cancel then
                behavior:cancel()
            end
            if behavior.reset then
                behavior:reset()
            end
        end
        if body.setPath2 then
            body:setPath2(nil)
        end
        local actionState = body.getActionStateName
            and string.lower(tostring(
                body:getActionStateName() or ""
            ))
            or ""
        if actionState == "pathfind"
            and body.changeState
            and ZombieIdleState
            and ZombieIdleState.instance
        then
            body:changeState(ZombieIdleState.instance())
        end
    end
    if LiveBodyControl
        and LiveBodyControl.EndNativeMovementLease
    then
        LiveBodyControl.EndNativeMovementLease(
            body,
            leaseKey
        )
    end
    state.owned = false
    state.leaseKey = nil
    state.requestKey = nil
    state.completed = false
    state.failed = false
    state.forcedTraversalUntil = nil
    state.forcedTraversalState = nil
    state.forcedTraversalAction = nil
end

local function beginMovementLease(body, state, key, now)
    state.leaseKey = key
    if LiveBodyControl
        and LiveBodyControl.BeginNativeMovementLease
    then
        LiveBodyControl.BeginNativeMovementLease(
            body,
            key,
            now,
            MOVEMENT_LEASE_MS
        )
    elseif body and body.setUseless then
        body:setUseless(false)
    end
end

local function finishOwnedPath(body, state, behavior)
    local leaseKey = state and state.leaseKey or nil
    if behavior then
        if behavior.cancel then behavior:cancel() end
        if behavior.reset then behavior:reset() end
    end
    if body and body.setPath2 then
        body:setPath2(nil)
    end
    if LiveBodyControl
        and LiveBodyControl.EndNativeMovementLease
    then
        LiveBodyControl.EndNativeMovementLease(
            body,
            leaseKey
        )
    end
    state.owned = false
    state.leaseKey = nil
    state.completed = true
    state.failed = false
end

local function nativeActionOwnsMovement(body)
    local actionState = body
        and body.getActionStateName
        and string.lower(tostring(
            body:getActionStateName() or ""
        ))
        or ""
    return actionState == "pathfind"
        or actionState == "climbfence"
        or actionState == "climbwindow"
        or actionState == "climbwall"
end

local function retryDelay(state)
    local retries = math.max(
        0,
        math.min(4, tonumber(state and state.retries) or 0)
    )
    return math.min(
        RETRY_MAX_MS,
        RETRY_BASE_MS * (2 ^ retries)
    )
end


Controller.EnsureState = ensureState
Controller.ClearOwnedPath = clearOwnedPath
Controller.BeginMovementLease = beginMovementLease
Controller.FinishOwnedPath = finishOwnedPath
Controller.NativeActionOwnsMovement = nativeActionOwnsMovement
Controller.RetryDelay = retryDelay
