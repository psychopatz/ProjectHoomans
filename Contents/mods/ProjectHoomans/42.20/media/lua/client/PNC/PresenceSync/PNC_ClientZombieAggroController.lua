-- Multiplayer zombie pursuit owner.
--
-- Build 42 delegates nearby IsoZombie simulation to a client. The server
-- remains authoritative for PNC health and bite damage, while this controller
-- owns native pursuit and targeting on the owning client. This follows the
-- proven Bandits pattern for human NPCs represented by IsoZombie shells.

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
local NATIVE_TARGET_DISTANCE = 3
local CONTROLLER_CHECK_MS = 250
local INDEX_REFRESH_MS = math.max(
    50,
    tonumber(Const.CLIENT_ZOMBIE_AGGRO_INDEX_MS) or 250
)
local INDEX_CELL_SIZE = math.max(
    2,
    tonumber(Const.CLIENT_ZOMBIE_AGGRO_CELL_SIZE) or 8
)
local AGGRO_TIER_MS = math.max(
    10,
    tonumber(Const.CLIENT_ZOMBIE_AGGRO_TIER_MS) or 50
)
local AGGRO_TIER_COUNT = math.max(
    1,
    math.floor(tonumber(Const.CLIENT_ZOMBIE_AGGRO_TIER_COUNT) or 4)
)
local CONTROLLER_BY_ZOMBIE =
    setmetatable({}, { __mode = "k" })
local NEXT_UPDATE_TIER = 0
local NPC_BODY_INDEX = {
    initialized = false,
    builtAt = 0,
    buckets = {},
}

-- TurnAlerted is still a vanilla engine transition. PNC no longer produces,
-- suppresses, or resets it, but the client aggro lane must not claim a zombie
-- while that engine-owned transition is active.
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

local function cellCoordinate(value)
    return math.floor((tonumber(value) or 0) / INDEX_CELL_SIZE)
end

local function bucketKey(cellX, cellY, z)
    return tostring(cellX)
        .. ":" .. tostring(cellY)
        .. ":" .. tostring(math.floor(tonumber(z) or 0))
end

local function rebuildNPCBodyIndex(now)
    local buckets = {}
    local id
    local body
    local key
    local bucket
    for id, body in pairs(Sync.BodyByID or {}) do
        if body then
            key = bucketKey(
                cellCoordinate(body:getX()),
                cellCoordinate(body:getY()),
                body:getZ()
            )
            bucket = buckets[key]
            if not bucket then
                bucket = {}
                buckets[key] = bucket
            end
            bucket[#bucket + 1] = {
                id = id,
                body = body,
            }
        end
    end
    NPC_BODY_INDEX.buckets = buckets
    NPC_BODY_INDEX.builtAt = now
    NPC_BODY_INDEX.initialized = true
end

local function ensureNPCBodyIndex(now)
    if not NPC_BODY_INDEX.initialized
        or now - NPC_BODY_INDEX.builtAt >= INDEX_REFRESH_MS
    then
        rebuildNPCBodyIndex(now)
    end
end

local function findNearestNPCBody(zombie, now)
    local bestBody
    local bestDistanceSq = AGGRO_RADIUS * AGGRO_RADIUS
    local radiusCells = math.ceil(AGGRO_RADIUS / INDEX_CELL_SIZE)
    local centerX = cellCoordinate(zombie:getX())
    local centerY = cellCoordinate(zombie:getY())
    local centerZ = math.floor(tonumber(zombie:getZ()) or 0)
    local offsetX
    local offsetY
    local offsetZ
    local bucket
    local entry
    local index
    local snapshot
    local dx
    local dy
    local distanceSq
    ensureNPCBodyIndex(now)
    for offsetZ = -1, 1 do
        for offsetX = -radiusCells, radiusCells do
            for offsetY = -radiusCells, radiusCells do
                bucket = NPC_BODY_INDEX.buckets[bucketKey(
                    centerX + offsetX,
                    centerY + offsetY,
                    centerZ + offsetZ
                )]
                if bucket then
                    for index = 1, #bucket do
                        entry = bucket[index]
                        snapshot = snapshotFor(entry.id)
                        if isTargetable(snapshot, entry.body)
                            and math.abs(
                                entry.body:getZ() - zombie:getZ()
                            ) < 1
                        then
                            dx = entry.body:getX() - zombie:getX()
                            dy = entry.body:getY() - zombie:getY()
                            distanceSq = (dx * dx) + (dy * dy)
                            if distanceSq < bestDistanceSq then
                                bestBody = entry.body
                                bestDistanceSq = distanceSq
                            end
                        end
                    end
                end
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
    if not entry then
        entry = {
            updateTier = NEXT_UPDATE_TIER,
        }
        NEXT_UPDATE_TIER =
            (NEXT_UPDATE_TIER + 1) % AGGRO_TIER_COUNT
        CONTROLLER_BY_ZOMBIE[zombie] = entry
    end
    if entry.owned == nil
        or now >= (tonumber(entry.nextAt) or 0)
    then
        entry.owned = not Internal.IsLocalZombieController
            or Internal.IsLocalZombieController(zombie)
        entry.nextAt = now + CONTROLLER_CHECK_MS
    end
    return entry.owned == true
end

local function isScheduledAggroTier(zombie, now)
    local entry = CONTROLLER_BY_ZOMBIE[zombie]
    local currentTier = math.floor(now / AGGRO_TIER_MS)
        % AGGRO_TIER_COUNT
    return entry ~= nil and entry.updateTier == currentTier
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
    local canSee = true
    if body.setZombiesDontAttack then
        body:setZombiesDontAttack(false)
    end
    if zombie.isUseless and zombie.setUseless
        and zombie:isUseless()
    then
        zombie:setUseless(false)
    end
    currentTarget = zombie.getTarget and zombie:getTarget() or nil
    if zombie.CanSee then
        canSee = zombie:CanSee(body) == true
    end
    if distanceSq > NATIVE_TARGET_DISTANCE * NATIVE_TARGET_DISTANCE then
        if shouldRefreshPath(zombie, body, now) then
            if canSee and zombie.pathToCharacter then
                zombie:pathToCharacter(body)
            elseif zombie.pathToLocationF then
                zombie:pathToLocationF(
                    body:getX(),
                    body:getY(),
                    body:getZ()
                )
            end
        end
    else
        -- Bandits establishes all four native relationships. Merely walking
        -- to coordinates never puts the zombie into its attack state.
        if zombie.spotted then
            zombie:spotted(body, true)
        end
        if zombie.addAggro then
            zombie:addAggro(body, 1)
        end
        if currentTarget ~= body and zombie.setTarget then
            zombie:setTarget(body)
        end
        if zombie.setAttackedBy then
            zombie:setAttackedBy(body)
        end
        if distanceSq <= BITE_DISTANCE * BITE_DISTANCE then
            if zombie.faceThisObject then
                zombie:faceThisObject(body)
            elseif zombie.faceLocation then
                zombie:faceLocation(
                    body:getX(),
                    body:getY()
                )
            end
        end
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", true)
        if isManagedBody(zombie.getTarget and zombie:getTarget() or nil) then
            zombie:setVariable("ZombieBiteDone", true)
        end
    end
    if zombie.setNoTeeth
        and isManagedBody(zombie.getTarget and zombie:getTarget() or nil)
    then
        zombie:setNoTeeth(true)
    end
end

local function releaseManagedTarget(zombie)
    local target = zombie.getTarget and zombie:getTarget() or nil
    local attackedBy = zombie.getAttackedBy
        and zombie:getAttackedBy() or nil
    if isManagedBody(target) and zombie.setTarget then
        zombie:setTarget(nil)
    end
    if isManagedBody(attackedBy) and zombie.setAttackedBy then
        zombie:setAttackedBy(nil)
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", false)
        zombie:setVariable("ZombieBiteDone", false)
    end
    if zombie.setNoTeeth then
        zombie:setNoTeeth(false)
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
    if not isScheduledAggroTier(zombie, now) then
        return false
    end
    body, distanceSq = findNearestNPCBody(zombie, now)
    if not body
        or currentPlayerDistanceSq(zombie) <= distanceSq
    then
        releaseManagedTarget(zombie)
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
