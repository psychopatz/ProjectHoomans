--[[
    Multiplayer native path controller.

    Build 42 gives a nearby client ownership of zombie simulation. Only the
    client closest to a PNC body submits the engine path request; PathFindState
    advances it. The server remains authoritative for goals, combat, and NPC
    records while normal IsoZombie networking transports the movement.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local Const = PNC.Const or {}
local LiveBodyControl = PNC.LiveBodyControl
local Network = PNC.Network

local CONTROLLER_CHECK_MS = 250
local PROGRESS_EPSILON_SQ = 0.0025
local STALL_TIMEOUT_MS = math.max(
    1500,
    tonumber(Const and Const.CLIENT_NATIVE_PATH_STALL_MS)
        or 3000
)
local RETRY_BASE_MS = math.max(
    250,
    tonumber(Const and Const.CLIENT_NATIVE_PATH_RETRY_BASE_MS)
        or 350
)
local RETRY_MAX_MS = math.max(
    RETRY_BASE_MS,
    tonumber(Const and Const.CLIENT_NATIVE_PATH_RETRY_MAX_MS)
        or 4000
)
local REQUEST_GRACE_MS = math.max(
    500,
    tonumber(Const and Const.CLIENT_NATIVE_PATH_REQUEST_GRACE_MS)
        or 900
)
local MOVEMENT_LEASE_MS = math.max(
    250,
    tonumber(Const and Const.CLIENT_NATIVE_MOVEMENT_LEASE_MS)
        or 750
)

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

local function hasBodyActionLock(body)
    local modData = body
        and body.getModData
        and body:getModData()
        or nil
    return modData ~= nil
        and (
            modData.PNC_BumpActionLease == true
            or modData.PNC_BumpReleasePending == true
        )
end

local function buildGoal(snapshot, body)
    local visualState = snapshot
        and snapshot.visualState or nil
    if not visualState
        or visualState.nativeMoveActive ~= true
        or visualState.attackActive == true
        or hasBodyActionLock(body)
    then
        return nil
    end
    local x = tonumber(visualState.nativeMoveX)
    local y = tonumber(visualState.nativeMoveY)
    local z = tonumber(visualState.nativeMoveZ)
    if x == nil or y == nil or z == nil then
        return nil
    end
    return {
        x = x,
        y = y,
        z = z,
        stopDistance = math.max(
            0.1,
            tonumber(visualState.nativeMoveStopDistance)
                or 0.7
        ),
        revision = tonumber(
            visualState.nativeMoveRevision
        ) or 0,
    }
end

local function distanceToGoalSquared(body, goal)
    local dx = goal.x - body:getX()
    local dy = goal.y - body:getY()
    local dz = math.abs(goal.z - body:getZ())
    if dz >= 0.5 then
        return math.huge
    end
    return (dx * dx) + (dy * dy)
end

local function rememberProgress(body, state, now)
    local x = body:getX()
    local y = body:getY()
    local z = body:getZ()
    local dx = x - (tonumber(state.lastX) or x)
    local dy = y - (tonumber(state.lastY) or y)
    local dz = z - (tonumber(state.lastZ) or z)
    if (dx * dx) + (dy * dy) + (dz * dz)
        >= PROGRESS_EPSILON_SQ
    then
        state.lastProgressAt = now
    end
    state.lastX = x
    state.lastY = y
    state.lastZ = z
end

local function requestKey(snapshot, goal)
    return table.concat({
        tostring(snapshot and snapshot.liveBodyLease or ""),
        tostring(goal.revision),
        tostring(goal.x),
        tostring(goal.y),
        tostring(goal.z),
    }, ":")
end

local function logState(snapshot, eventName, extra)
    if Internal.LogClientMotionDebug then
        Internal.LogClientMotionDebug(
            snapshot,
            snapshot and snapshot.id or nil,
            eventName,
            extra
        )
    end
end

local function describeBody(body)
    local onlineID = Network
        and Network.GetZombieOnlineID
        and Network.GetZombieOnlineID(body)
        or nil
    local actionState = body
        and body.getActionStateName
        and body:getActionStateName()
        or "unknown"
    local useless = body
        and body.isUseless
        and body:isUseless()
        or false
    local hasPath = body
        and body.getPath2
        and body:getPath2() ~= nil
        or false
    return " bodyOnlineID=" .. tostring(onlineID or "nil")
        .. " pos=" .. tostring(body and body:getX() or "nil")
        .. "," .. tostring(body and body:getY() or "nil")
        .. "," .. tostring(body and body:getZ() or "nil")
        .. " action=" .. tostring(actionState)
        .. " useless=" .. tostring(useless)
        .. " path2=" .. tostring(hasPath)
end

function Internal.BindNativePathSnapshot(snapshot, body, now)
    if not body
        or not Core
        or not Core.IsClientOnly
        or Core.IsClientOnly() ~= true
    then
        return false
    end
    now = tonumber(now)
        or (Core.Now and Core.Now() or 0)
    local state = ensureState(body)
    local goal = buildGoal(snapshot, body)
    local key = goal and requestKey(snapshot, goal) or nil
    state.snapshot = snapshot
    state.lastSeenAt = now
    state.releasePending = false
    -- Presence visuals run immediately after this bind. Release a delegated
    -- PathFindBehavior2 route here, before PlayBump selects the attack clip;
    -- waiting for the later OnZombieUpdate callback lets pathfind locomotion
    -- swallow the first (and often only) melee animation edge.
    if not goal
        and state.owned == true
        and (
            hasBodyActionLock(body)
            or (
                snapshot
                and snapshot.visualState
                and snapshot.visualState.attackActive == true
            )
        )
    then
        clearOwnedPath(body, state)
    end
    if goal
        and (
            state.requestKey ~= key
            or state.owned == true
        )
    then
        beginMovementLease(body, state, key, now)
    elseif not goal
        and LiveBodyControl
        and LiveBodyControl.EndNativeMovementLease
    then
        LiveBodyControl.EndNativeMovementLease(
            body,
            state.leaseKey
        )
        state.leaseKey = nil
    end
    if (goal or hasBodyActionLock(body))
        and LiveBodyControl
        and LiveBodyControl.SetManagedBodyUseless
    then
        LiveBodyControl.SetManagedBodyUseless(
            body,
            false,
            true
        )
    elseif (goal or hasBodyActionLock(body))
        and body.setUseless
    then
        body:setUseless(false)
    end
    return goal ~= nil
end

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
    local shouldRequest =
        state.requestKey ~= key
        or (
            state.failed == true
            and now >= (tonumber(state.retryAt) or 0)
        )
    if shouldRequest then
        if state.owned == true then
            if behavior.cancel then
                behavior:cancel()
            end
            if behavior.reset then
                behavior:reset()
            end
        end
        -- Build 42.19 requires the character wrapper here. It enters
        -- PathFindState, which is the sole owner of PathFindBehavior2.update()
        -- and of native door/window/fence traversal. Calling update() from Lua
        -- leaves WalkTowardState and path2 active together and floods warnings.
        body:pathToLocationF(goal.x, goal.y, goal.z)
        if state.requestKey ~= key then
            state.retries = 0
        else
            state.retries =
                (tonumber(state.retries) or 0) + 1
        end
        state.requestKey = key
        state.owned = true
        state.completed = false
        state.failed = false
        state.startedAt = now
        state.lastProgressAt = now
        state.lastX = body:getX()
        state.lastY = body:getY()
        state.lastZ = body:getZ()
        beginMovementLease(body, state, key, now)
        logState(
            snapshot,
            "native_controller_start",
            "goal=" .. tostring(goal.x)
                .. "," .. tostring(goal.y)
                .. "," .. tostring(goal.z)
                .. " revision=" .. tostring(goal.revision)
                .. " retry=" .. tostring(state.retries)
                .. describeBody(body)
        )
    end
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
    if nativeActionOwnsMovement(body) then
        local actionState = string.lower(tostring(
            body:getActionStateName() or ""
        ))
        if actionState ~= "pathfind" then
            state.lastProgressAt = now
        end
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

function Internal.OnNativePathZombieUpdate(body)
    local state = body
        and Sync.NativePathStateByBody[body] or nil
    local snapshot = state and state.snapshot or nil
    if state and state.releasePending == true then
        clearOwnedPath(body, state)
        Sync.NativePathStateByBody[body] = nil
        return
    end
    if not snapshot then
        return
    end
    -- Match Bandits' ManageActionState boundary on every zombie frame. The
    -- engine owns locomotion/traversal, but never target selection or zombie
    -- feeding behavior for a managed human body.
    if LiveBodyControl and LiveBodyControl.SuppressVanillaIntent then
        LiveBodyControl.SuppressVanillaIntent(
            body,
            buildGoal(snapshot, body) ~= nil
                or hasBodyActionLock(body)
        )
    end
    Internal.UpdateNativePathController(
        snapshot,
        body,
        Core and Core.Now and Core.Now() or 0
    )
end

function Internal.ClearNativePathControllers()
    local body
    local state
    for body, state in pairs(
        Sync.NativePathStateByBody or {}
    ) do
        clearOwnedPath(body, state)
    end
    Sync.NativePathStateByBody = {}
end

function Internal.PruneNativePathControllers(now)
    now = tonumber(now)
        or (Core and Core.Now and Core.Now() or 0)
    local body
    local state
    for body, state in pairs(
        Sync.NativePathStateByBody or {}
    ) do
        if now - (tonumber(state.lastSeenAt) or 0) >= 500 then
            if state.owned == true then
                -- PathFindBehavior2 lifecycle changes stay in the zombie's
                -- update event, just like Bandits' Move.onComplete.
                state.snapshot = nil
                state.releasePending = true
            else
                Sync.NativePathStateByBody[body] = nil
            end
        end
    end
end

if Events and Events.OnZombieUpdate then
    if Sync.NativePathZombieUpdateHandler then
        Events.OnZombieUpdate.Remove(
            Sync.NativePathZombieUpdateHandler
        )
    end
    Sync.NativePathZombieUpdateHandler =
        Internal.OnNativePathZombieUpdate
    Events.OnZombieUpdate.Add(
        Sync.NativePathZombieUpdateHandler
    )
end

return Internal
