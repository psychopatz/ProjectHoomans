-- Multiplayer zombie pursuit owner.
--
-- Build 42 delegates nearby IsoZombie simulation to a client. The server
-- remains authoritative for PNC health and bite damage, while this controller
-- owns coordinate pursuit on the owning client. PNC NPC bodies are IsoZombie
-- shells, so they must never be installed as NetworkZombieMind character
-- goals; the server owns the target lease and bite damage separately.

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local Const = PNC.Const or {}
local ClientState = PNC.Network and PNC.Network.ClientState or nil

local PATH_REFRESH_MS = tonumber(
    Const.ZOMBIE_NPC_PATH_REFRESH_MS
) or 350
local PATH_REFRESH_DISTANCE = tonumber(
    Const.ZOMBIE_NPC_PATH_REFRESH_DISTANCE
) or 0.6
local AGGRO_RADIUS = tonumber(Const.ZOMBIE_AGGRO_RADIUS) or 12
local BITE_DISTANCE = tonumber(Const.ZOMBIE_BITE_DISTANCE) or 1.2
local CONTROLLER_CHECK_MS = 250
local CONTROLLER_BY_ZOMBIE =
    setmetatable({}, { __mode = "k" })

local ACTION_OWNED_ELSEWHERE = {
    bumped = true,
    climbfence = true,
    climbwindow = true,
    getup = true,
    onground = true,
    staggerback = true,
    turnalerted = true,
}

local function isManagedBody(body)
    return Core
        and Core.IsManagedNPCBody
        and Core.IsManagedNPCBody(body)
        or false
end

local function snapshotFor(id)
    return ClientState
        and ClientState.snapshots
        and ClientState.snapshots[tostring(id)]
        or nil
end

local function isTargetable(snapshot, body)
    return snapshot
        and snapshot.presenceState == Const.PRESENCE_LIVE
        and snapshot.zombieTargetable == true
        and body
        and not (body.isDead and body:isDead())
end

local function findNearestNPCBody(zombie)
    local bestBody
    local bestDistanceSq = AGGRO_RADIUS * AGGRO_RADIUS
    local id
    local body
    local snapshot
    local dx
    local dy
    local distanceSq
    for id, body in pairs(Sync.BodyByID or {}) do
        snapshot = snapshotFor(id)
        if isTargetable(snapshot, body)
            and math.abs(body:getZ() - zombie:getZ()) < 1
        then
            dx = body:getX() - zombie:getX()
            dy = body:getY() - zombie:getY()
            distanceSq = (dx * dx) + (dy * dy)
            if distanceSq < bestDistanceSq then
                bestBody = body
                bestDistanceSq = distanceSq
            end
        end
    end
    return bestBody, bestDistanceSq
end

local function currentPlayerDistanceSq(zombie)
    local target = zombie.getTarget and zombie:getTarget() or nil
    local dx
    local dy
    if not target
        or not instanceof
        or not instanceof(target, "IsoPlayer")
    then
        return math.huge
    end
    dx = target:getX() - zombie:getX()
    dy = target:getY() - zombie:getY()
    return (dx * dx) + (dy * dy)
end

local function isLocalOwner(zombie, now)
    local entry = CONTROLLER_BY_ZOMBIE[zombie]
    if not entry or now >= (tonumber(entry.nextAt) or 0) then
        entry = entry or {}
        entry.owned = not Internal.IsLocalZombieController
            or Internal.IsLocalZombieController(zombie)
        entry.nextAt = now + CONTROLLER_CHECK_MS
        CONTROLLER_BY_ZOMBIE[zombie] = entry
    end
    return entry.owned == true
end

local function shouldRefreshPath(zombie, body, now)
    local modData = zombie.getModData
        and zombie:getModData() or nil
    local x = body:getX()
    local y = body:getY()
    local lastX = modData
        and tonumber(modData.PNC_ClientAggroPathX) or nil
    local lastY = modData
        and tonumber(modData.PNC_ClientAggroPathY) or nil
    local dx = lastX and x - lastX or math.huge
    local dy = lastY and y - lastY or math.huge
    if modData
        and now - (
            tonumber(modData.PNC_ClientAggroPathAt) or 0
        ) < PATH_REFRESH_MS
        and (dx * dx) + (dy * dy)
            < PATH_REFRESH_DISTANCE * PATH_REFRESH_DISTANCE
    then
        return false
    end
    if modData then
        modData.PNC_ClientAggroPathAt = now
        modData.PNC_ClientAggroPathX = x
        modData.PNC_ClientAggroPathY = y
    end
    return true
end

local function applyAggro(zombie, body, distanceSq, now)
    local currentTarget
    if body.setZombiesDontAttack then
        body:setZombiesDontAttack(false)
    end
    if zombie.isUseless and zombie.setUseless
        and zombie:isUseless()
    then
        zombie:setUseless(false)
    end
    currentTarget = zombie.getTarget and zombie:getTarget() or nil
    if isManagedBody(currentTarget) and zombie.setTarget then
        zombie:setTarget(nil)
    end
    if distanceSq > BITE_DISTANCE * BITE_DISTANCE then
        -- PathFindState may pursue coordinates for an IsoZombie-shaped NPC.
        -- pathToCharacter/setTarget/spotted are intentionally forbidden here:
        -- Build 42's MP zombie mind can only network supported character goals.
        if shouldRefreshPath(zombie, body, now) then
            if zombie.pathToLocationF then
                zombie:pathToLocationF(
                    body:getX(),
                    body:getY(),
                    body:getZ()
                )
            end
        end
    elseif zombie.faceLocation then
        zombie:faceLocation(
            body:getX(),
            body:getY()
        )
    elseif zombie.faceThisObject then
        zombie:faceThisObject(body)
    end
    if zombie.getAttackedBy and zombie.setAttackedBy then
        local attackedBy = zombie:getAttackedBy()
        if isManagedBody(attackedBy) then
            zombie:setAttackedBy(nil)
        end
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", true)
    end
end

function Internal.UpdateClientZombieAggro(zombie, now)
    local actionState
    local body
    local distanceSq
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if not zombie
        or isManagedBody(zombie)
        or (zombie.isDead and zombie:isDead())
        or not isLocalOwner(zombie, now)
    then
        return false
    end
    actionState = zombie.getActionStateName
        and string.lower(tostring(
            zombie:getActionStateName() or ""
        ))
        or ""
    if ACTION_OWNED_ELSEWHERE[actionState]
        or (zombie.isProne and zombie:isProne())
    then
        return false
    end
    body, distanceSq = findNearestNPCBody(zombie)
    if not body
        or currentPlayerDistanceSq(zombie) <= distanceSq
    then
        if zombie.setVariable then
            zombie:setVariable("NoLungeAttack", false)
        end
        return false
    end
    applyAggro(
        zombie,
        body,
        distanceSq,
        now
    )
    return true
end

function Internal.OnClientZombieAggroUpdate(zombie)
    Internal.UpdateClientZombieAggro(
        zombie,
        Core and Core.Now and Core.Now() or 0
    )
end

if Events and Events.OnZombieUpdate
    and isClient and isClient() == true
then
    if Sync.ClientZombieAggroUpdateHandler then
        Events.OnZombieUpdate.Remove(
            Sync.ClientZombieAggroUpdateHandler
        )
    end
    Sync.ClientZombieAggroUpdateHandler =
        Internal.OnClientZombieAggroUpdate
    Events.OnZombieUpdate.Add(
        Sync.ClientZombieAggroUpdateHandler
    )
end

return Internal
