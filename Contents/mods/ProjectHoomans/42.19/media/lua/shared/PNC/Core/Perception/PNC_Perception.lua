--[[
    PNC Perception
    Owns nearby hostile resolution, zombie target scanning, and helper queries
    used by behavior, combat, and zombie aggro bridge systems.
]]

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}

local Perception = PNC.Perception
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex
local Stealth = PNC.Stealth
local Registry = PNC.Registry
local Relationships = PNC.Relationships
Perception.OwnerThreatCache = Perception.OwnerThreatCache or {}

local function isImmediateThreat(target)
    local radius = tonumber(Const.TARGET_IMMEDIATE_THREAT_RADIUS) or 6
    return target and target.threatening == true
        and (tonumber(target.distSq) or math.huge) <= (radius * radius)
end

local function pickNearest(firstTarget, secondTarget)
    local firstThreat
    local secondThreat
    if not firstTarget then
        return secondTarget
    end
    if not secondTarget then
        return firstTarget
    end
    firstThreat = isImmediateThreat(firstTarget)
    secondThreat = isImmediateThreat(secondTarget)
    if firstThreat ~= secondThreat then
        return firstThreat and firstTarget or secondTarget
    end
    if (tonumber(firstTarget.distSq) or math.huge) <= (tonumber(secondTarget.distSq) or math.huge) then
        return firstTarget
    end
    return secondTarget
end

local function sameTarget(target, kind, id, onlineID, username)
    if not target or tostring(target.kind or "") ~= tostring(kind or "") then
        return false
    end
    if kind == "npc" then
        return tostring(target.id or "") == tostring(id or "")
    end
    if kind == "zombie" then
        return tostring(target.zombieId or "") == tostring(id or "")
    end
    if kind == "player" then
        if onlineID ~= nil and target.onlineID ~= nil then
            return tonumber(target.onlineID) == tonumber(onlineID)
        end
        return username ~= nil and tostring(target.username or "") == tostring(username)
    end
    return false
end

local function targetPointsAtRecord(target, record)
    if not target or not record then return false end
    return tostring(target.kind or "") == "npc"
        and tostring(target.id or "") == tostring(record.id or "")
end

function Perception.RememberAttacker(record, damageEvent, now)
    local kind
    local id
    if not record or type(damageEvent) ~= "table" then return false end
    kind = tostring(damageEvent.attackerKind or "")
    if kind ~= "npc" and kind ~= "player" and kind ~= "zombie" then
        return false
    end
    if kind == "npc" then
        id = damageEvent.attackerID
    elseif kind == "zombie" then
        id = damageEvent.attackerZombieId or damageEvent.zombieId
    end
    if (kind == "npc" or kind == "zombie") and (id == nil or id == "") then
        return false
    end
    if kind == "player"
        and damageEvent.attackerOnlineID == nil
        and (damageEvent.attackerUsername == nil or damageEvent.attackerUsername == "")
    then
        return false
    end
    record.runtime = record.runtime or {}
    record.runtime.recentThreat = {
        kind = kind,
        id = id,
        onlineID = damageEvent.attackerOnlineID,
        username = damageEvent.attackerUsername,
        expiresAt = (tonumber(now) or Core.Now())
            + (tonumber(Const.TARGET_RECENT_ATTACKER_MS) or 5000),
    }
    if Perception.InvalidateFrame then
        Perception.InvalidateFrame(record)
    end
    return true
end

function Perception.ResolveRecentAttacker(record, now)
    local recent
    local kind
    local targetRecord
    local worldObject
    local x
    local y
    local z
    local target
    if not record or not record.runtime then
        return nil
    end
    recent = record.runtime.recentThreat
    now = tonumber(now) or Core.Now()
    if not recent or now > (tonumber(recent.expiresAt) or 0) then
        record.runtime.recentThreat = nil
        return nil
    end
    kind = tostring(recent.kind or "")
    if kind == "npc" then
        targetRecord = Registry
            and Registry.Get
            and Registry.Get(recent.id)
            or nil
        if not targetRecord or targetRecord.alive == false then
            return nil
        end
        if Relationships
            and Relationships.AreNPCsEnemies
            and not Relationships.AreNPCsEnemies(record, targetRecord)
        then
            return nil
        end
        worldObject = Registry
            and Registry.GetLiveZombie
            and Registry.GetLiveZombie(recent.id)
            or nil
        if not worldObject or (worldObject.isDead and worldObject:isDead()) then
            return nil
        end
        x = worldObject:getX()
        y = worldObject:getY()
        z = worldObject:getZ()
        target = {
            kind = "npc",
            id = recent.id,
        }
    elseif kind == "player" then
        worldObject = Core.ResolvePlayerByOnlineID(recent.onlineID)
            or Core.ResolvePlayerByUsername(recent.username)
        if not worldObject
            or (worldObject.isDead and worldObject:isDead())
            or (worldObject.isAlive and not worldObject:isAlive())
        then
            return nil
        end
        x = worldObject:getX()
        y = worldObject:getY()
        z = worldObject:getZ()
        target = {
            kind = "player",
            player = worldObject,
            onlineID = recent.onlineID,
            username = recent.username,
        }
    elseif kind == "zombie" then
        worldObject = Perception.FindZombieByID
            and Perception.FindZombieByID(recent.id)
            or nil
        if not worldObject or (worldObject.isDead and worldObject:isDead()) then
            return nil
        end
        x = worldObject:getX()
        y = worldObject:getY()
        z = worldObject:getZ()
        target = {
            kind = "zombie",
            zombieId = recent.id,
            worldObject = worldObject,
        }
    else
        return nil
    end
    target.x = x
    target.y = y
    target.z = z
    target.distSq = Core.DistanceSq(record.x, record.y, x, y)
    target.visible = true
    target.visibilityKind = "recent_attacker"
    target.lastSeenAt = now
    target.threatening = true
    return target
end

function Perception.IsTargetThreatening(record, target)
    local recent
    local targetRecord
    local targetBody
    local observerBody
    local engineTarget
    if not record or not target then return false end
    recent = record.runtime and record.runtime.recentThreat or nil
    if recent and Core.Now() <= (tonumber(recent.expiresAt) or 0)
        and sameTarget(
            target,
            recent.kind,
            recent.id,
            recent.onlineID,
            recent.username
        )
    then
        return true
    end
    if target.kind == "npc" then
        targetRecord = Registry and Registry.Get and Registry.Get(target.id) or nil
        return targetRecord ~= nil
            and targetPointsAtRecord(targetRecord.runtime and targetRecord.runtime.target, record)
    end
    if target.kind == "zombie" then
        targetBody = target.zombie
            or (Perception.FindZombieByID and Perception.FindZombieByID(target.zombieId))
        observerBody = Registry and Registry.GetLiveZombie
            and Registry.GetLiveZombie(record.id)
            or nil
        if targetBody and observerBody and targetBody.getTarget then
            local ok
            ok, engineTarget = pcall(targetBody.getTarget, targetBody)
            return ok and engineTarget == observerBody
        end
    end
    return false
end

function Perception.SelectPreferredTarget(firstTarget, secondTarget)
    return pickNearest(firstTarget, secondTarget)
end

local function isRecordEnemy(source, target)
    return Relationships and Relationships.AreNPCsEnemies
        and Relationships.AreNPCsEnemies(source, target)
        or false
end

function Perception.CanSeeWorldObject(record, targetObject)
    local observer
    local cell
    local result
    local resultName
    local runtime
    local cache
    local bucket
    local cached
    local visible
    if not record or not targetObject then
        return false
    end
    record.runtime = record.runtime or {}
    runtime = record.runtime
    bucket = math.floor(Core.Now() / 100)
    cache = runtime.perceptionVisibilityCache
    if not cache or cache.bucket ~= bucket then
        cache = { bucket = bucket, values = {} }
        runtime.perceptionVisibilityCache = cache
    end
    cached = cache.values[targetObject]
    if cached ~= nil then
        return cached == "clear" or cached == "clearthroughopendoor" or cached == "clearthroughwindow", cached
    end
    observer = Registry and Registry.GetLiveZombie and Registry.GetLiveZombie(record.id) or nil
    if not observer or (observer.isDead and observer:isDead()) then
        return false
    end
    if math.abs(observer:getZ() - targetObject:getZ()) >= 1 then
        return false
    end
    cell = getCell and getCell() or nil
    if not cell or not LosUtil or not LosUtil.lineClear then
        return false
    end
    result = LosUtil.lineClear(
        cell,
        math.floor(observer:getX()),
        math.floor(observer:getY()),
        math.floor(observer:getZ()),
        math.floor(targetObject:getX()),
        math.floor(targetObject:getY()),
        math.floor(targetObject:getZ()),
        false
    )
    resultName = string.lower(tostring(result or ""))
    visible = resultName == "clear"
        or resultName == "clearthroughopendoor"
        or resultName == "clearthroughwindow"
    cache.values[targetObject] = resultName
    return visible == true, resultName
end

local function buildZombieTarget(record, zombie, distSq, visibilityKind)
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    local zombieId = modData and modData.PNC_ZombieID or nil
    if not zombieId and Spatial and Spatial.GetZombieID then
        zombieId = Spatial.GetZombieID(zombie)
    end
    if not zombieId then
        return nil
    end
    local target = {
        kind = "zombie",
        zombie = zombie,
        zombieId = zombieId,
        x = zombie:getX(),
        y = zombie:getY(),
        z = zombie:getZ(),
        distSq = distSq,
        visible = true,
        visibilityKind = visibilityKind or "clear",
        lastSeenAt = Core.Now(),
    }
    target.threatening = Perception.IsTargetThreatening(record, target)
    target.zombie = nil
    return target
end

local function collectEnemyZombies(record, radius)
    local zombies
    local results = {}
    local i
    local zombie
    local distSq
    local visible
    local visibilityKind
    if not record or not Spatial or not Spatial.QueryZombies then
        return results
    end
    radius = tonumber(radius) or Const.ZOMBIE_TARGET_RADIUS
    if Perception.GetVisibleZombieEntries then
        return Perception.GetVisibleZombieEntries(record, radius)
    end
    zombies = Spatial.QueryZombies(record.x, record.y, radius)
    for i = 1, #zombies do
        zombie = zombies[i]
        if zombie and (not zombie:isDead()) and (not Core.IsManagedNPCBody(zombie)) and math.abs(zombie:getZ() - record.z) < 1 then
            distSq = Core.DistanceSq(record.x, record.y, zombie:getX(), zombie:getY())
            visible, visibilityKind = Perception.CanSeeWorldObject(record, zombie)
            if distSq <= (radius * radius) and visible then
                results[#results + 1] = {
                    zombie = zombie,
                    distSq = distSq,
                    visibilityKind = visibilityKind,
                }
            end
        end
    end
    return results
end

function Perception.FindNearestEnemyPlayer(record, radius)
    radius = tonumber(radius) or Const.ZOMBIE_TARGET_RADIUS
    local players = Spatial.QueryPlayers(record.x, record.y, radius)
    local best = nil
    local i
    local player
    local distSq
    local visible
    local visibilityKind
    local candidate

    for i = 1, #players do
        player = players[i]
        visible = false
        visibilityKind = nil
        if player then
            visible, visibilityKind = Perception.CanSeeWorldObject(record, player)
        end
        if player and player:isAlive() and math.abs(player:getZ() - record.z) < 1 and visible then
            distSq = Core.DistanceSq(record.x, record.y, player:getX(), player:getY())
            if distSq <= (radius * radius) then
                candidate = {
                    kind = "player",
                    player = player,
                    onlineID = player:getOnlineID(),
                    username = player:getUsername(),
                    x = player:getX(),
                    y = player:getY(),
                    z = player:getZ(),
                    distSq = distSq,
                    visible = true,
                    visibilityKind = visibilityKind,
                    lastSeenAt = Core.Now(),
                }
                candidate.threatening = Perception.IsTargetThreatening(record, candidate)
                best = pickNearest(best, candidate)
            end
        end
    end
    return best
end

function Perception.FindNearestEnemyNPC(record, radius)
    radius = tonumber(radius) or Const.ZOMBIE_TARGET_RADIUS
    local npcs = Spatial.QueryNPCs(record.x, record.y, radius)
    local best = nil
    local i
    local target
    local targetZombie
    local distSq
    local visible
    local visibilityKind
    local candidate

    for i = 1, #npcs do
        target = npcs[i]
        targetZombie = target and Registry and Registry.GetLiveZombie and Registry.GetLiveZombie(target.id) or nil
        visible = false
        visibilityKind = nil
        if targetZombie then
            visible, visibilityKind = Perception.CanSeeWorldObject(record, targetZombie)
        end
        if target and target.alive ~= false and targetZombie and isRecordEnemy(record, target) and math.abs(target.z - record.z) < 1
            and visible
        then
            distSq = Core.DistanceSq(record.x, record.y, target.x, target.y)
            if distSq <= (radius * radius) then
                candidate = {
                    kind = "npc",
                    id = target.id,
                    x = target.x,
                    y = target.y,
                    z = target.z,
                    distSq = distSq,
                    visible = true,
                    visibilityKind = visibilityKind,
                    lastSeenAt = Core.Now(),
                }
                candidate.threatening = Perception.IsTargetThreatening(record, candidate)
                best = pickNearest(best, candidate)
            end
        end
    end
    return best
end

function Perception.FindNearestEnemyZombie(record, radius)
    local zombies
    local best
    local i
    local entry
    local candidate

    if not record or record.hostility and record.hostility.attackZombies == false then
        return nil
    end

    best = nil
    zombies = collectEnemyZombies(record, radius)
    for i = 1, #zombies do
        entry = zombies[i]
        if entry then
            candidate = buildZombieTarget(record, entry.zombie, entry.distSq, entry.visibilityKind)
            best = pickNearest(best, candidate)
        end
    end

    return best
end

function Perception.FindBestEnemyZombie(record, radius)
    local candidates
    local best
    local bestScore
    local i
    local j
    local entry
    local other
    local crowdCount
    local score
    local target
    local targetIsThreat
    local bestIsThreat
    local crowdRadiusSq = (tonumber(Const.COMBAT_TARGET_CROWD_RADIUS) or 2.2) ^ 2
    local crowdPenalty = 1.6

    if not record or record.hostility and record.hostility.attackZombies == false then
        return nil
    end

    candidates = collectEnemyZombies(record, radius)
    bestScore = math.huge
    for i = 1, #candidates do
        entry = candidates[i]
        if entry and entry.zombie then
            crowdCount = 0
            for j = 1, #candidates do
                other = candidates[j]
                if other and other.zombie and other.zombie ~= entry.zombie
                    and math.abs(other.zombie:getZ() - entry.zombie:getZ()) < 1
                    and Core.DistanceSq(entry.zombie:getX(), entry.zombie:getY(), other.zombie:getX(), other.zombie:getY()) <= crowdRadiusSq
                then
                    crowdCount = crowdCount + 1
                end
            end
            score = entry.distSq + (crowdCount * crowdCount * crowdPenalty)
            target = buildZombieTarget(record, entry.zombie, entry.distSq, entry.visibilityKind)
            targetIsThreat = isImmediateThreat(target)
            bestIsThreat = isImmediateThreat(best)
            if (targetIsThreat and not bestIsThreat)
                or (targetIsThreat == bestIsThreat and score < bestScore)
            then
                best = target
                bestScore = score
            end
        end
    end
    return best
end

function Perception.CountEnemyZombies(record, radius)
    local zombies
    local count = 0
    local i
    local entry

    if not record or record.hostility and record.hostility.attackZombies == false then
        return 0
    end

    if Perception.CountZombiesInFrame then
        return Perception.CountZombiesInFrame(
            record,
            tonumber(radius) or Const.ZOMBIE_TARGET_RADIUS
        )
    end
    zombies = collectEnemyZombies(record, radius)
    for i = 1, #zombies do
        entry = zombies[i]
        if entry then
            count = count + 1
        end
    end

    return count
end

function Perception.FindZombieByID(zombieId)
    local zombie
    if not zombieId or not Spatial or not Spatial.FindZombieByID then
        return nil
    end
    zombie = Spatial.FindZombieByID(zombieId)
    if zombie then
        return zombie
    end
    if Spatial.Rebuild then
        Spatial.Rebuild(Core.Now(), false)
        return Spatial.FindZombieByID(zombieId)
    end
    return nil
end

local function getCompanionDefenseRadius()
    return math.max(8, tonumber(Const.ZOMBIE_TARGET_RADIUS) or 12)
end

local function ownerThreatCacheKey(owner)
    local onlineID = owner and owner.getOnlineID
        and owner:getOnlineID() or nil
    local username = owner and owner.getUsername
        and owner:getUsername() or nil
    if onlineID ~= nil and (tonumber(onlineID) or -1) >= 0 then
        return "id:" .. tostring(onlineID)
    end
    if username and tostring(username) ~= "" then
        return "user:" .. tostring(username)
    end
    return tostring(owner)
end

local function buildOwnerThreatTarget(record, owner, zombie)
    local ok
    local engineTarget
    local candidate
    if not zombie or zombie:isDead()
        or Core.IsManagedNPCBody(zombie)
        or math.abs(zombie:getZ() - owner:getZ()) >= 1
        or not zombie.getTarget
    then
        return nil
    end
    ok, engineTarget = pcall(zombie.getTarget, zombie)
    if not ok or engineTarget ~= owner then
        return nil
    end
    candidate = buildZombieTarget(
        record,
        zombie,
        Core.DistanceSq(
            record.x,
            record.y,
            zombie:getX(),
            zombie:getY()
        ),
        "owner_under_attack"
    )
    if candidate then
        candidate.threatening = true
        candidate.defendingOwner = true
    end
    return candidate
end

local function findZombieTargetingOwner(record, owner, radius)
    local zombies
    local bestZombie
    local bestOwnerDistSq
    local radiusSq
    local i
    local zombie
    local ok
    local engineTarget
    local ownerDistSq
    local now
    local cacheKey
    local cached
    if not record or not owner or not Spatial or not Spatial.QueryZombies then
        return nil
    end
    now = Core.Now()
    cacheKey = ownerThreatCacheKey(owner)
    cached = Perception.OwnerThreatCache[cacheKey]
    if cached and now < (tonumber(cached.expiresAt) or 0) then
        if cached.zombie == false then
            return nil
        end
        local cachedTarget = buildOwnerThreatTarget(
            record,
            owner,
            cached.zombie
        )
        if cachedTarget then
            return cachedTarget
        end
    end
    radius = math.max(1, tonumber(radius) or getCompanionDefenseRadius())
    radiusSq = radius * radius
    zombies = Spatial.QueryZombies(owner:getX(), owner:getY(), radius)
    bestOwnerDistSq = math.huge
    for i = 1, #zombies do
        zombie = zombies[i]
        if zombie and not zombie:isDead()
            and not Core.IsManagedNPCBody(zombie)
            and math.abs(zombie:getZ() - owner:getZ()) < 1
            and zombie.getTarget
        then
            ok, engineTarget = pcall(zombie.getTarget, zombie)
            if ok and engineTarget == owner then
                ownerDistSq = Core.DistanceSq(
                    owner:getX(),
                    owner:getY(),
                    zombie:getX(),
                    zombie:getY()
                )
                if ownerDistSq <= radiusSq
                    and ownerDistSq < bestOwnerDistSq
                then
                    bestZombie = zombie
                    bestOwnerDistSq = ownerDistSq
                end
            end
        end
    end
    Perception.OwnerThreatCache[cacheKey] = {
        zombie = bestZombie or false,
        expiresAt = now + (
            tonumber(Const.COMPANION_OWNER_THREAT_CACHE_MS) or 100
        ),
    }
    return buildOwnerThreatTarget(record, owner, bestZombie)
end

function Perception.FindOwnerThreateningZombie(record, owner, radius)
    return findZombieTargetingOwner(record, owner, radius)
end

function Perception.ResolveCompanionTarget(record)
    local owner
    local ownerThreatZombie
    local npcTarget
    local zombieTarget
    local hostileToOwnerNPC
    local hostileToOwnerZombie
    local defenseRadius = getCompanionDefenseRadius()

    owner = Core.ResolvePlayerByOnlineID(record.ownerOnlineID) or Core.ResolvePlayerByUsername(record.ownerUsername)
    if owner and (not record.hostility or record.hostility.attackZombies ~= false) then
        ownerThreatZombie = findZombieTargetingOwner(
            record,
            owner,
            defenseRadius
        )
        if ownerThreatZombie then
            return ownerThreatZombie
        end
    end

    if Stealth and Stealth.ShouldSuppressCompanionCombat and Stealth.ShouldSuppressCompanionCombat(record) then
        record.runtime = record.runtime or {}
        record.runtime.targetKind = "none"
        record.runtime.combatBlockReason = "follow_stealth_hidden"
        return nil
    end

    if not record.hostility or record.hostility.attackNPCs ~= false then
        npcTarget = Perception.FindNearestEnemyNPC(record, defenseRadius)
    end
    if not record.hostility or record.hostility.attackZombies ~= false then
        zombieTarget = Perception.FindBestEnemyZombie(record, defenseRadius)
    end
    if npcTarget or zombieTarget then
        return pickNearest(npcTarget, zombieTarget)
    end

    if owner then
        hostileToOwnerNPC = (not record.hostility or record.hostility.attackNPCs ~= false) and Perception.FindNearestEnemyNPC({
            id = record.id,
            faction = record.faction,
            x = owner:getX(),
            y = owner:getY(),
            z = owner:getZ(),
            hostility = record.hostility,
        }, defenseRadius)
        hostileToOwnerZombie = (not record.hostility or record.hostility.attackZombies ~= false) and Perception.FindBestEnemyZombie({
            id = record.id,
            faction = record.faction,
            x = owner:getX(),
            y = owner:getY(),
            z = owner:getZ(),
            hostility = record.hostility,
        }, defenseRadius)
        return pickNearest(hostileToOwnerNPC, hostileToOwnerZombie)
    end

    return nil
end

function Perception.ResolveHostileTarget(record)
    local hostileConfig = record and record.hostility or {}
    local npcTarget = nil
    local playerTarget = nil
    local zombieTarget = nil

    if hostileConfig.attackNPCs ~= false then
        npcTarget = Perception.FindNearestEnemyNPC(record, 12)
    end
    if hostileConfig.attackPlayers ~= false then
        playerTarget = Perception.FindNearestEnemyPlayer(record, 12)
    end
    if hostileConfig.attackZombies ~= false then
        zombieTarget = Perception.FindBestEnemyZombie(record, Const.ZOMBIE_TARGET_RADIUS)
    end

    return pickNearest(pickNearest(npcTarget, playerTarget), zombieTarget)
end

function Perception.ResolveRoamingTarget(record, radius)
    local hostility = record and record.hostility or {}
    local searchRadius = math.max(1, tonumber(radius) or Const.ROAM_TARGET_RADIUS or 12)
    local npcTarget = nil
    local playerTarget = nil
    local zombieTarget = nil

    if hostility.attackNPCs ~= false then
        npcTarget = Perception.FindNearestEnemyNPC(record, searchRadius)
    end
    if hostility.attackPlayers == true then
        playerTarget = Perception.FindNearestEnemyPlayer(record, searchRadius)
    end
    if hostility.attackZombies ~= false then
        zombieTarget = Perception.FindBestEnemyZombie(record, searchRadius)
    end

    return pickNearest(pickNearest(npcTarget, playerTarget), zombieTarget)
end
