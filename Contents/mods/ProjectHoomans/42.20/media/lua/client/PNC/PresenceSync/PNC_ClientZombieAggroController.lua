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
local Network = PNC.Network
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
local INDEX_REFRESH_MS = math.max(
    250,
    tonumber(Const.CLIENT_BODY_SCAN_MS) or 750
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
local DIRECTIVE_BODY_CACHE = {}
local DIRECTIVE_BODY_LOOKUP_MS = 250
local releaseManagedTarget
local applyAggro

-- TurnAlerted is still a vanilla engine transition. PNC no longer produces,
-- suppresses, or resets it, but the client aggro lane must not claim a zombie
-- while that engine-owned transition is active.
local ACTION_OWNED_ELSEWHERE = {
    ["attack"] = true,
    ["attack-network"] = true,
    bumped = true,
    climbfence = true,
    climbwindow = true,
    getup = true,
    onground = true,
    staggerback = true,
    turnalerted = true,
}

local function isActionOwnedElsewhere(actionState)
    return ACTION_OWNED_ELSEWHERE[actionState] == true
        or string.find(actionState, "hitreaction", 1, true) == 1
        or string.find(actionState, "staggerback", 1, true) == 1
        or string.find(actionState, "knockdown", 1, true) == 1
        or string.find(actionState, "falldown", 1, true) == 1
        or string.find(actionState, "ragdoll", 1, true) == 1
        or string.find(actionState, "lunge", 1, true) == 1
end

local function isMultiplayerActionOwnedElsewhere(actionState)
    return actionState == "thump"
        or isActionOwnedElsewhere(actionState)
end

local function isMultiplayerMode()
    return (isServer and isServer() == true)
        or (isClient and isClient() == true)
end

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
    local modData
    if not body or (body.isDead and body:isDead()) then
        return false
    end
    if snapshot then
        return snapshot.presenceState == Const.PRESENCE_LIVE
            and snapshot.alive ~= false
            and snapshot.zombieTargetable == true
    end
    modData = body.getModData and body:getModData() or nil
    return modData
        and modData.PNC_NPC == true
        and modData.PNC_UUID ~= nil
        and tostring(modData.PNC_BodyKind or "live") ~= "corpse"
        or false
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
    local seenBodies = {}
    local id
    local snapshot
    local body
    local key
    local bucket
    local foundBody = false
    local bodyByID = Sync.BodyByID or {}
    local ambiguousIDs = {}

    for candidateID, candidate in pairs(bodyByID) do
        if candidate == false then
            ambiguousIDs[tostring(candidateID)] = true
        end
    end

    local function addBody(candidate, candidateID, candidateSnapshot)
        if not candidate or seenBodies[candidate]
            or not isTargetable(candidateSnapshot, candidate)
        then
            return
        end
        seenBodies[candidate] = true
        key = bucketKey(
            cellCoordinate(candidate:getX()),
            cellCoordinate(candidate:getY()),
            candidate:getZ()
        )
        bucket = buckets[key]
        if not bucket then
            bucket = {}
            buckets[key] = bucket
        end
        bucket[#bucket + 1] = {
            id = candidateID,
            body = candidate,
        }
        foundBody = true
    end

    -- BodyByID is populated by PNC_ClientPresenceBodies from the actual local
    -- cell zombie list. Unlike the old snapshot loop, it also contains bodies
    -- whose roster entry is not detailed for this client.
    for id, body in pairs(bodyByID) do
        snapshot = snapshotFor(id)
        addBody(body, id, snapshot)
    end

    -- Cover the short window before the shared body map sees a newly streamed
    -- shell. This is deliberately throttled with the index refresh interval.
    if not foundBody and getCell then
        local cell = getCell()
        local zombieList = cell and cell.getZombieList
            and cell:getZombieList() or nil
        local index
        if zombieList then
            for index = 0, zombieList:size() - 1 do
                body = zombieList:get(index)
                local modData = body and body.getModData
                    and body:getModData() or nil
                id = modData and modData.PNC_UUID or nil
                snapshot = id and snapshotFor(id) or nil
                if id == nil or not ambiguousIDs[tostring(id)] then
                    addBody(body, id, snapshot)
                end
            end
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

local function isLivePlayer(player)
    return player
        and instanceof
        and instanceof(player, "IsoPlayer")
        and not (player.isDead and player:isDead())
end

local function findNearestPlayer(zombie)
    local bestPlayer
    local bestDistanceSq = math.huge
    local seenPlayers = {}
    local currentTarget = zombie.getTarget
        and zombie:getTarget() or nil
    local zombieZ = zombie:getZ()
    local zombieX = zombie:getX()
    local zombieY = zombie:getY()

    local function consider(player)
        local dx
        local dy
        local distanceSq
        if not isLivePlayer(player) or seenPlayers[player]
            or math.abs(player:getZ() - zombieZ) >= 1
        then
            return
        end
        seenPlayers[player] = true
        dx = player:getX() - zombieX
        dy = player:getY() - zombieY
        distanceSq = (dx * dx) + (dy * dy)
        if distanceSq < bestDistanceSq then
            bestPlayer = player
            bestDistanceSq = distanceSq
        end
    end

    -- Preserve the engine's current player target as a candidate even when
    -- it is outside the local player list. This prevents an NPC inside the
    -- search radius from displacing a farther player unless it is actually
    -- the nearer target.
    consider(currentTarget)

    if getOnlinePlayers then
        local players = getOnlinePlayers()
        local i
        if players and players.size then
            for i = 0, players:size() - 1 do
                consider(players:get(i))
            end
        end
    end
    if getNumActivePlayers and getSpecificPlayer then
        local i
        for i = 0, getNumActivePlayers() - 1 do
            consider(getSpecificPlayer(i))
        end
    end
    return bestPlayer, bestDistanceSq
end

local function findNearestTarget(zombie, now)
    local npcBody
    local npcDistanceSq
    local player
    local playerDistanceSq
    npcBody, npcDistanceSq = findNearestNPCBody(zombie, now)
    player, playerDistanceSq = findNearestPlayer(zombie)
    if npcBody and npcDistanceSq < playerDistanceSq then
        return npcBody, npcDistanceSq, true
    end
    return player, playerDistanceSq, false
end

local function clearHeldItems(zombie)
    -- Build 42's multiplayer dropHeavyItems path sends a player-only packet.
    -- Ordinary zombies can reach that path while pursuing a managed NPC, so
    -- mirror Bandits and remove carried items before native pursuit continues.
    if zombie.getPrimaryHandItem and zombie:getPrimaryHandItem()
        and zombie.setPrimaryHandItem
    then
        zombie:setPrimaryHandItem(nil)
    end
    if zombie.getSecondaryHandItem and zombie:getSecondaryHandItem()
        and zombie.setSecondaryHandItem
    then
        zombie:setSecondaryHandItem(nil)
    end
    -- Bandits also clear the equipped/attached visual state in MP. Keep this
    -- traversal safeguard out of the restored singleplayer lane.
    if isMultiplayerMode() then
        if zombie.resetEquippedHandsModels then
            zombie:resetEquippedHandsModels()
        end
        if zombie.clearAttachedItems then
            zombie:clearAttachedItems()
        end
    end
end

local function clearNativeCombatTarget(zombie)
    -- NPCs are IsoZombie shells. Never place one in IsoZombie.target or
    -- attackedBy: Build 42 AttackState casts those native combat slots to
    -- IsoPlayer during animation events. Movement uses pathToCharacter while
    -- damage is handled by the abstract server lane.
    if zombie.setTarget then zombie:setTarget(nil) end
    if zombie.setAttackedBy then zombie:setAttackedBy(nil) end
    if zombie.setTargetSeenTime then zombie:setTargetSeenTime(0) end
    if zombie.clearAggroList then zombie:clearAggroList() end
end

local function ensureControllerEntry(zombie)
    local entry = CONTROLLER_BY_ZOMBIE[zombie]
    if not entry then
        entry = {
            updateTier = NEXT_UPDATE_TIER,
        }
        NEXT_UPDATE_TIER =
            (NEXT_UPDATE_TIER + 1) % AGGRO_TIER_COUNT
        CONTROLLER_BY_ZOMBIE[zombie] = entry
    end
    return entry
end

local function isScheduledAggroTier(zombie, now)
    local entry = ensureControllerEntry(zombie)
    local currentTier = math.floor(now / AGGRO_TIER_MS)
        % AGGRO_TIER_COUNT
    return entry.updateTier == currentTier
end

local function isLocalZombieUpdate(zombie)
    -- Build 42 raises OnZombieUpdate for the local simulation lane. Keep this
    -- guard for the short remote-shell update window without touching the
    -- non-exposed server-side UdpConnection owner object.
    return not zombie.isRemoteZombie or zombie:isRemoteZombie() ~= true
end

local function isMultiplayerDirectiveLane()
    return isMultiplayerMode()
end

local function getMPTargetDirective(zombie, now)
    local onlineID
    local directives
    local key
    local directive
    if not isMultiplayerDirectiveLane()
        or not Network
        or not Network.GetZombieOnlineID
        or not ClientState
    then
        return nil
    end
    onlineID = Network.GetZombieOnlineID(zombie)
    if onlineID == nil then
        return nil
    end
    directives = ClientState.zombiePursuitDirectives or {}
    key = tostring(onlineID)
    directive = directives[key]
    if directive and now >= (tonumber(directive.expiresAt) or 0) then
        directives[key] = nil
        if PNC.PerformanceScalingDiagnostics
            and PNC.PerformanceScalingDiagnostics.Increment
        then
            PNC.PerformanceScalingDiagnostics.Increment(
                "ZombieAggro.MPDirectiveExpired"
            )
        end
        directive = nil
    end
    return directive
end

local function resolveDirectiveBody(npcId, now)
    local key
    local cached
    local body
    local cell
    local zombieList
    local index
    local candidate
    local modData
    local matchCount
    if npcId == nil then
        return nil
    end
    key = tostring(npcId)
    cached = DIRECTIVE_BODY_CACHE[key]
    if cached and now - (tonumber(cached.checkedAt) or 0)
        < DIRECTIVE_BODY_LOOKUP_MS
    then
        return cached.body
    end
    body = Sync.BodyByID and Sync.BodyByID[key] or nil
    if body == false then
        body = nil
    end
    -- BodyByID is the normal O(1) route. A bounded fallback covers the
    -- replication window where the shell has arrived before the periodic
    -- body-map scan has indexed it. Refuse ambiguous duplicates.
    if not body and getCell then
        cell = getCell()
        zombieList = cell and cell.getZombieList
            and cell:getZombieList() or nil
        matchCount = 0
        if zombieList then
            for index = 0, zombieList:size() - 1 do
                candidate = zombieList:get(index)
                modData = candidate and candidate.getModData
                    and candidate:getModData() or nil
                if modData
                    and modData.PNC_NPC == true
                    and tostring(modData.PNC_UUID or "") == key
                    and tostring(modData.PNC_BodyKind or "live") ~= "corpse"
                then
                    matchCount = matchCount + 1
                    body = candidate
                end
            end
        end
        if matchCount ~= 1 then
            body = nil
        end
    end
    if body and body.isDead and body:isDead() then
        body = nil
    end
    DIRECTIVE_BODY_CACHE[key] = {
        body = body,
        checkedAt = now,
    }
    return body
end

local function shouldRefreshPath(zombie, targetX, targetY, now)
    local modData = zombie.getModData
        and zombie:getModData() or nil
    local x = tonumber(targetX) or zombie:getX()
    local y = tonumber(targetY) or zombie:getY()
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

local function applySingleplayerAggro(zombie, body, distanceSq, now)
    local currentTarget
    local canSee = true
    clearHeldItems(zombie)
    if body.setZombiesDontAttack then
        body:setZombiesDontAttack(false)
    end
    if zombie.isUseless and zombie.setUseless
        and zombie:isUseless()
    then
        zombie:setUseless(false)
    end
    currentTarget = zombie.getTarget and zombie:getTarget() or nil
    -- Restore the prior SP movement handoff. The path request is transient;
    -- WalkTowardState continues from zombie.target on the next engine update.
    if currentTarget ~= body and zombie.setTarget then
        zombie:setTarget(body)
        if distanceSq > (3.5 * 3.5) and zombie.spotted then
            zombie:spotted(body, false)
        end
        currentTarget = body
    end
    if zombie.CanSee then
        canSee = zombie:CanSee(body) == true
    end
    if distanceSq > NATIVE_TARGET_DISTANCE * NATIVE_TARGET_DISTANCE then
        if shouldRefreshPath(
            zombie,
            body:getX(),
            body:getY(),
            now
        )
        then
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
                zombie:faceLocation(body:getX(), body:getY())
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

local function applyMultiplayerAggro(
    zombie,
    body,
    distanceSq,
    now,
    targetX,
    targetY,
    targetZ,
    directiveRevision
)
    local modData = zombie.getModData
        and zombie:getModData() or nil
    local canSee
    local pathRequested = false
    targetX = body and body:getX() or tonumber(targetX)
    targetY = body and body:getY() or tonumber(targetY)
    targetZ = body and body:getZ() or tonumber(targetZ)
    if modData and directiveRevision ~= nil
        and tostring(modData.PNC_ClientAggroDirectiveRevision or "")
            ~= tostring(directiveRevision)
    then
        modData.PNC_ClientAggroDirectiveRevision = directiveRevision
        modData.PNC_ClientAggroPathAt = 0
        modData.PNC_ClientAggroPathX = nil
        modData.PNC_ClientAggroPathY = nil
    end
    clearHeldItems(zombie)
    clearNativeCombatTarget(zombie)
    if body and body.setZombiesDontAttack then
        body:setZombiesDontAttack(false)
    end
    if zombie.isUseless and zombie.setUseless
        and zombie:isUseless()
    then
        zombie:setUseless(false)
    end
    -- Match Bandits for movement, but do not copy its native combat-target
    -- handoff. PNC damage is abstract, so path toward the NPC at every range.
    if shouldRefreshPath(zombie, targetX, targetY, now) then
        -- Bandits only request native character pursuit after the exposed LOS
        -- check. This avoids repeatedly pushing a zombie into a traversal
        -- transition that can invoke the player-only drop-items packet.
        canSee = body and zombie.CanSee and zombie:CanSee(body) or false
        if body and canSee and zombie.pathToCharacter then
            zombie:pathToCharacter(body)
            pathRequested = true
        elseif not body and targetX and targetY and targetZ
            and zombie.pathToLocationF
        then
            -- The server directive carries a coordinate fallback for the
            -- brief shell-streaming gap. Once the shell is visible, the LOS
            -- guarded pathToCharacter branch takes over.
            zombie:pathToLocationF(targetX, targetY, targetZ)
            pathRequested = true
        elseif PNC.PerformanceScalingDiagnostics
            and PNC.PerformanceScalingDiagnostics.Increment
        then
            PNC.PerformanceScalingDiagnostics.Increment(
                "ZombieAggro.MPPathSkippedNoLOS"
            )
        end
        if pathRequested
            and PNC.PerformanceScalingDiagnostics
            and PNC.PerformanceScalingDiagnostics.Increment
        then
            PNC.PerformanceScalingDiagnostics.Increment(
                "ZombieAggro.MPPathRequests"
            )
        end
    end
    if body and distanceSq <= BITE_DISTANCE * BITE_DISTANCE then
        if zombie.faceThisObject then
            zombie:faceThisObject(body)
        elseif zombie.faceLocation then
            zombie:faceLocation(
                body:getX(),
                body:getY()
            )
        end
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", true)
    end
end

applyAggro = function(...)
    if isMultiplayerDirectiveLane() then
        return applyMultiplayerAggro(...)
    end
    return applySingleplayerAggro(...)
end

local function applyPlayerTarget(zombie, player)
    local currentTarget = zombie.getTarget and zombie:getTarget() or nil
    if isManagedBody(currentTarget) then
        releaseManagedTarget(zombie)
        currentTarget = zombie.getTarget and zombie:getTarget() or nil
    end
    if player and currentTarget ~= player and zombie.setTarget then
        zombie:setTarget(player)
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", false)
    end
end

releaseManagedTarget = function(zombie)
    local target = zombie.getTarget and zombie:getTarget() or nil
    local attackedBy = zombie.getAttackedBy
        and zombie:getAttackedBy() or nil
    if isManagedBody(target) and zombie.setTarget then
        zombie:setTarget(nil)
    end
    if isManagedBody(attackedBy) and zombie.setAttackedBy then
        zombie:setAttackedBy(nil)
    end
    if zombie.setTargetSeenTime then
        zombie:setTargetSeenTime(0)
    end
    if zombie.clearAggroList then
        zombie:clearAggroList()
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", false)
        zombie:setVariable("ZombieBiteDone", false)
    end
    if zombie.setNoTeeth then
        zombie:setNoTeeth(false)
    end
end

function Internal.ResetClientZombieAggro()
    CONTROLLER_BY_ZOMBIE = setmetatable({}, { __mode = "k" })
    NEXT_UPDATE_TIER = 0
    NPC_BODY_INDEX.initialized = false
    NPC_BODY_INDEX.builtAt = 0
    NPC_BODY_INDEX.buckets = {}
    DIRECTIVE_BODY_CACHE = {}
end

function Internal.UpdateClientZombieAggro(zombie, now)
    local actionState
    local body
    local distanceSq
    local target
    local targetIsNPC
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if not zombie
        or isManagedBody(zombie)
        or (zombie.isDead and zombie:isDead())
        or not isLocalZombieUpdate(zombie)
    then
        return false
    end
    actionState = zombie.getActionStateName
        and string.lower(tostring(
            zombie:getActionStateName() or ""
        ))
        or ""
    if (isMultiplayerDirectiveLane()
        and isMultiplayerActionOwnedElsewhere(actionState))
        or (not isMultiplayerDirectiveLane()
            and ACTION_OWNED_ELSEWHERE[actionState] == true)
        or (zombie.isProne and zombie:isProne())
    then
        return false
    end
    if not isScheduledAggroTier(zombie, now) then
        return false
    end

    -- Multiplayer target selection is server-authoritative. Do not run a
    -- client-side nearest-NPC scan here: it has no knowledge of the zombie's
    -- owning simulation lane and is exactly why clients kept choosing players.
    if isMultiplayerDirectiveLane() then
        local directive = getMPTargetDirective(zombie, now)
        local targetBody
        local targetDistanceSq
        local targetX
        local targetY
        local targetZ
        if not directive then
            releaseManagedTarget(zombie)
            return false
        end
        targetBody = resolveDirectiveBody(directive.npcId, now)
        targetX = targetBody and targetBody:getX() or directive.x
        targetY = targetBody and targetBody:getY() or directive.y
        targetZ = targetBody and targetBody:getZ() or directive.z
        if not targetX or not targetY or not targetZ then
            releaseManagedTarget(zombie)
            return false
        end
        targetDistanceSq = Core.DistanceSq(
            zombie:getX(),
            zombie:getY(),
            targetX,
            targetY
        )
        applyAggro(
            zombie,
            targetBody,
            targetDistanceSq,
            now,
            targetX,
            targetY,
            targetZ,
            directive.revision
        )
        if PNC.PerformanceScalingDiagnostics
            and PNC.PerformanceScalingDiagnostics.Increment
        then
            PNC.PerformanceScalingDiagnostics.Increment(
                "ZombieAggro.MPDirectiveApplied"
            )
        end
        return true
    end

    target, distanceSq, targetIsNPC = findNearestTarget(zombie, now)
    if not target then
        releaseManagedTarget(zombie)
        return false
    end
    if not targetIsNPC then
        applyPlayerTarget(zombie, target)
        return false
    end
    body = target
    if not body
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
