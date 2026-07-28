--[[
    Multiplayer native path controller.

    Build 42 gives a nearby client ownership of zombie simulation. Mirroring
    Bandits, only the client closest to a PNC body advances PathFindBehavior2.
    The server remains authoritative for goals, combat, and NPC records while
    normal IsoZombie networking transports the resulting movement.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local Network = PNC.Network

local RETRY_DELAY_MS = 500
local MAX_RETRIES = 3
local CONTROLLER_CHECK_MS = 250

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

local function isLocalController(body)
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

local function resultMatches(result, name)
    if BehaviorResult and BehaviorResult[name] ~= nil then
        return result == BehaviorResult[name]
    end
    local value = tostring(result or "")
    return value == name
        or value == ("BehaviorResult." .. name)
end

local function clearOwnedPath(body, state)
    local behavior
    if not body or not state or state.owned ~= true then
        return
    end
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
    state.owned = false
    state.requestKey = nil
    state.completed = false
    state.failed = false
end

local function buildGoal(snapshot)
    local visualState = snapshot
        and snapshot.visualState or nil
    if not visualState
        or visualState.nativeMoveActive ~= true
        or visualState.attackActive == true
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
        revision = tonumber(
            visualState.nativeMoveRevision
        ) or 0,
    }
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
    state.snapshot = snapshot
    state.lastSeenAt = now
    state.releasePending = false
    if LiveBodyControl
        and LiveBodyControl.SetManagedBodyUseless
    then
        LiveBodyControl.SetManagedBodyUseless(
            body,
            false,
            true
        )
    elseif body.setUseless then
        body:setUseless(false)
    end
    return buildGoal(snapshot) ~= nil
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
    if LiveBodyControl
        and LiveBodyControl.SetManagedBodyUseless
    then
        LiveBodyControl.SetManagedBodyUseless(
            body,
            false,
            true
        )
    elseif body.setUseless then
        body:setUseless(false)
    end

    local state = ensureState(body)
    state.snapshot = snapshot
    state.lastSeenAt = now
    local goal = buildGoal(snapshot)
    if not goal then
        clearOwnedPath(body, state)
        return false, "native_goal_inactive"
    end
    if state.localController == nil
        or now >= (
            tonumber(state.nextControllerCheckAt) or 0
        )
    then
        state.localController = isLocalController(body)
        state.nextControllerCheckAt =
            now + CONTROLLER_CHECK_MS
    end
    if state.localController ~= true then
        if state.owned == true then
            clearOwnedPath(body, state)
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
    if not behavior
        or not behavior.update
        or (not behavior.pathToLocation
            and not behavior.pathToLocationF)
    then
        return false, "native_path_api_unavailable"
    end

    local key = requestKey(snapshot, goal)
    local shouldRequest =
        state.requestKey ~= key
        or (
            state.failed == true
            and state.retries < MAX_RETRIES
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
        if behavior.pathToLocation then
            behavior:pathToLocation(
                goal.x,
                goal.y,
                goal.z
            )
        else
            behavior:pathToLocationF(
                goal.x,
                goal.y,
                goal.z
            )
        end
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

    local result = behavior:update()
    if resultMatches(result, "Succeeded") then
        state.completed = true
        logState(
            snapshot,
            "native_controller_complete",
            "revision=" .. tostring(goal.revision)
        )
        return true, "native_path_succeeded"
    end
    if resultMatches(result, "Failed") then
        state.failed = true
        state.retryAt = now + RETRY_DELAY_MS
        logState(
            snapshot,
            "native_controller_failed",
            "revision=" .. tostring(goal.revision)
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
    -- Match Bandits' ZAMove execution context. Build 42 assigns zombie
    -- simulation ownership while the zombie itself is being updated; pumping
    -- PathFindBehavior2 from generic OnTick can leave a replica animating
    -- without advancing its networked position.
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
