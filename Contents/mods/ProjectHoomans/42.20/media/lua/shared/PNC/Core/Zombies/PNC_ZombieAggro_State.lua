PNC = PNC or {}
PNC.ZombieAggro = PNC.ZombieAggro or {}

local ZombieAggro = PNC.ZombieAggro
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Stealth = PNC.Stealth
local Settings = PNC.Sandbox

ZombieAggro.State = ZombieAggro.State or {
    bites = {},
}
ZombieAggro.Internal = ZombieAggro.Internal or {}

local Internal = ZombieAggro.Internal

local PURSUIT_OWNER = "ProjectHoomans"
local PURSUIT_LEASE_KEY = "PNC_ZombiePursuit"
local DEFAULT_PURSUIT_PRIORITIES = {
    ProjectHoomans = 100,
    Bandits = 60,
    NecroaHordeMaker = 30,
}

local function pursuitPriority(owner, requested)
    local value = tonumber(requested)
    if value ~= nil then return value end
    return tonumber(DEFAULT_PURSUIT_PRIORITIES[tostring(owner or "")]) or 0
end

local function logPursuitLease(zombie, targetId, state, detail, now)
    if ZombieAggro.LogPursuitDiagnostic then
        ZombieAggro.LogPursuitDiagnostic(
            zombie, targetId, "lease", state, detail, now
        )
    end
end

local function pursuitModData(zombie)
    return zombie and zombie.getModData and zombie:getModData() or nil
end

local function clearPursuitLeaseData(modData, owner)
    if type(modData) ~= "table" then return end
    if owner == nil or tostring(modData["PNC_ZombiePursuitOwner"] or "")
        == tostring(owner)
    then
        modData["PNC_ZombiePursuitOwner"] = nil
        modData["PNC_ZombiePursuitProvider"] = nil
        modData["PNC_ZombiePursuitTarget"] = nil
        modData["PNC_ZombiePursuitRevision"] = nil
        modData["PNC_ZombiePursuitUntil"] = nil
        modData["PNC_ZombiePursuitPriority"] = nil
        modData["PNC_ZombiePursuitReason"] = nil
    end
end

function Internal.GetPursuitLease(zombie, now)
    local modData = pursuitModData(zombie)
    local owner
    local expiresAt
    if not modData then return nil end
    owner = modData["PNC_ZombiePursuitOwner"]
    expiresAt = tonumber(modData["PNC_ZombiePursuitUntil"])
    now = tonumber(now) or Core.Now()
    if owner == nil or expiresAt == nil or expiresAt <= now then
        clearPursuitLeaseData(modData)
        return nil
    end
    return {
        owner = tostring(owner),
        provider = modData["PNC_ZombiePursuitProvider"],
        targetId = modData["PNC_ZombiePursuitTarget"],
        revision = tonumber(modData["PNC_ZombiePursuitRevision"]) or 0,
        expiresAt = expiresAt,
        priority = tonumber(modData["PNC_ZombiePursuitPriority"])
            or pursuitPriority(owner, nil),
        reason = modData["PNC_ZombiePursuitReason"],
        key = PURSUIT_LEASE_KEY,
    }
end

function Internal.AcquirePursuitLease(
    zombie, owner, provider, targetId, now, ttl, priority, reason
)
    local modData = pursuitModData(zombie)
    local current
    local revision
    local ownerValue
    local providerValue
    local targetValue
    local priorityValue
    local reasonValue
    local changed
    if not modData or owner == nil then return false end
    now = tonumber(now) or Core.Now()
    ttl = tonumber(ttl) or tonumber(Const.ZOMBIE_NPC_AGGRO_LEASE_MS) or 8000
    ownerValue = tostring(owner)
    providerValue = provider ~= nil and tostring(provider) or nil
    targetValue = targetId ~= nil and tostring(targetId) or nil
    priorityValue = pursuitPriority(ownerValue, priority)
    reasonValue = reason ~= nil and tostring(reason) or nil
    current = Internal.GetPursuitLease(zombie, now)
    if current and current.owner ~= ownerValue then
        if priorityValue <= (tonumber(current.priority) or 0) then
            logPursuitLease(
                zombie,
                targetValue,
                "pursuit_lease_denied",
                "requestOwner=" .. ownerValue
                    .. " requestPriority=" .. tostring(priorityValue)
                    .. " currentOwner=" .. tostring(current.owner)
                    .. " currentPriority=" .. tostring(current.priority),
                now
            )
            return false
        end
    end
    changed = not current
        or current.owner ~= ownerValue
        or tostring(current.provider or "") ~= tostring(providerValue or "")
        or tostring(current.targetId or "") ~= tostring(targetValue or "")
        or (tonumber(current.priority) or 0) ~= priorityValue
        or tostring(current.reason or "") ~= tostring(reasonValue or "")
    revision = tonumber(modData["PNC_ZombiePursuitRevision"]) or 0
    if changed then revision = revision + 1 end
    modData["PNC_ZombiePursuitOwner"] = ownerValue
    modData["PNC_ZombiePursuitProvider"] = providerValue
    modData["PNC_ZombiePursuitTarget"] = targetValue
    modData["PNC_ZombiePursuitRevision"] = revision
    modData["PNC_ZombiePursuitUntil"] = now + math.max(1, ttl)
    modData["PNC_ZombiePursuitPriority"] = priorityValue
    modData["PNC_ZombiePursuitReason"] = reasonValue
    if changed then
        logPursuitLease(
            zombie,
            targetValue,
            "pursuit_lease_acquired",
            "owner=" .. ownerValue
                .. " provider=" .. tostring(providerValue)
                .. " priority=" .. tostring(priorityValue)
                .. " reason=" .. tostring(reasonValue),
            now
        )
    end
    return true, revision
end

function Internal.ReleasePursuitLease(zombie, owner)
    local modData = pursuitModData(zombie)
    if not modData then return false end
    if owner ~= nil and tostring(modData["PNC_ZombiePursuitOwner"] or "")
        ~= tostring(owner)
    then
        return false
    end
    clearPursuitLeaseData(modData, owner)
    return true
end

function Internal.ShouldYieldToPursuitOwner(
    zombie, owner, now, requestedPriority
)
    local lease = Internal.GetPursuitLease(zombie, now)
    if not lease or lease.owner == tostring(owner or "") then
        return false
    end
    return (tonumber(lease.priority) or 0)
        >= pursuitPriority(owner, requestedPriority)
end

-- Public compatibility boundary. Foreign AI mods can cooperate without
-- depending on Hoomans' internal module layout or load order.
ZombieAggro.Pursuit = ZombieAggro.Pursuit or {}
ZombieAggro.Pursuit.GetLease = function(zombie, now)
    return Internal.GetPursuitLease(zombie, now)
end
ZombieAggro.Pursuit.TryAcquire = function(
    zombie, owner, provider, targetId, now, ttl, priority, reason
)
    return Internal.AcquirePursuitLease(
        zombie, owner, provider, targetId, now, ttl, priority, reason
    )
end
ZombieAggro.Pursuit.Release = function(zombie, owner)
    return Internal.ReleasePursuitLease(zombie, owner)
end
ZombieAggro.Pursuit.ShouldYield = function(
    zombie, owner, now, requestedPriority
)
    return Internal.ShouldYieldToPursuitOwner(
        zombie, owner, now, requestedPriority
    )
end

local function isForeignOwnedBody(body)
    local ownership = PNC.Compatibility
        and PNC.Compatibility.ActorOwnership or nil
    return ownership
        and ownership.IsForeignOwned
        and ownership.IsForeignOwned(body) == true
        or false
end

function Internal.ensureZombieID(zombie)
    local modData
    if not zombie or not zombie.getModData then
        return nil
    end
    modData = zombie:getModData()
    if not modData then
        return nil
    end
    if not modData.PNC_ZombieID or tostring(modData.PNC_ZombieID) == "" then
        modData.PNC_ZombieID = Core.GenerateID("pz")
    end
    return modData.PNC_ZombieID
end

function Internal.getZombieModData(zombie)
    return zombie and zombie.getModData and zombie:getModData() or nil
end

function Internal.rememberZombieAttacker(
    record,
    zombie,
    phase,
    now,
    distSq
)
    local runtime
    local existing
    local zombieId
    local onlineID
    local path2
    if not record or not zombie then return nil end
    now = tonumber(now) or Core.Now()
    distSq = tonumber(distSq) or Core.DistanceSq(
        zombie:getX(),
        zombie:getY(),
        record.x or zombie:getX(),
        record.y or zombie:getY()
    )
    runtime = record.runtime or {}
    record.runtime = runtime
    zombieId = Internal.ensureZombieID(zombie)
    existing = runtime.zombieAttacker
    if existing
        and tostring(existing.zombieId or "")
            ~= tostring(zombieId or "")
        and (now - (tonumber(existing.observedAt) or 0)) < 750
        and (tonumber(existing.distSq) or math.huge) <= distSq
    then
        return existing
    end
    onlineID = zombie.getOnlineID
        and tonumber(zombie:getOnlineID()) or nil
    if onlineID and onlineID < 0 then onlineID = nil end
    path2 = zombie.getPath2 and zombie:getPath2() or nil
    runtime.zombieAttacker = {
        zombieId = zombieId,
        onlineID = onlineID,
        phase = tostring(phase or "pursuit"),
        observedAt = now,
        x = zombie:getX(),
        y = zombie:getY(),
        z = zombie:getZ(),
        distSq = distSq,
        actionState = zombie.getActionStateName
            and tostring(zombie:getActionStateName() or "")
            or "",
        bumpType = zombie.getBumpType
            and tostring(zombie:getBumpType() or "")
            or "",
        path2Active = path2 ~= nil,
    }
    return runtime.zombieAttacker
end

local function clearForcedNPC(modData)
    if modData then
        modData.PNC_AggroNPCId = nil
        modData.PNC_AggroNPCUntil = nil
        modData.PNC_AggroPathAt = nil
        modData.PNC_AggroPathX = nil
        modData.PNC_AggroPathY = nil
    end
end

function Internal.isManagedNPCBody(zombie)
    return Core.IsManagedNPCBody(zombie)
end

function Internal.clearZombieTarget(zombie)
    local modData
    if not zombie then
        return
    end
    modData = Internal.getZombieModData(zombie)
    clearForcedNPC(modData)
    Internal.ReleasePursuitLease(zombie, PURSUIT_OWNER)
    if zombie.clearAggroList then
        zombie:clearAggroList()
    end
    -- On an MP server the owning client drives the native zombie mind, as in
    -- Bandits. Do not broadcast a target clear every authority pump and fight
    -- that client's pursuit/attack state. The server lease still decides which
    -- NPC is valid and remains authoritative for bite damage.
    if not (isServer and isServer() == true) then
        if zombie.setTarget then
            zombie:setTarget(nil)
        end
        if zombie.setAttackedBy then
            zombie:setAttackedBy(nil)
        end
    end
    if zombie.setVariable then
        zombie:setVariable("NoLungeAttack", false)
    end
end

function Internal.getForcedNPCBodyTarget(zombie, now)
    local modData
    local npcId
    local record
    local npcBody
    if not zombie then
        return nil, nil
    end
    modData = Internal.getZombieModData(zombie)
    npcId = modData and modData.PNC_AggroNPCId or nil
    if not npcId then
        return nil, nil
    end
    now = tonumber(now) or Core.Now()
    if now >= (tonumber(modData.PNC_AggroNPCUntil) or 0) then
        clearForcedNPC(modData)
        Internal.ReleasePursuitLease(zombie, PURSUIT_OWNER)
        return nil, nil
    end
    record = Registry.Get(npcId)
    npcBody = Registry.GetLiveZombie(npcId)
    if not record or not npcBody or record.alive == false
        or record.presenceState ~= Const.PRESENCE_LIVE
        or not Settings.CanZombieTargetRecord(record)
    then
        clearForcedNPC(modData)
        Internal.ReleasePursuitLease(zombie, PURSUIT_OWNER)
        return nil, nil
    end
    if npcBody.isDead and npcBody:isDead() then
        clearForcedNPC(modData)
        Internal.ReleasePursuitLease(zombie, PURSUIT_OWNER)
        return nil, nil
    end
    return record, npcBody
end

function Internal.isCloseLivePlayerTarget(zombie, target)
    local dx
    local dy
    if not zombie or not target or not instanceof or not instanceof(target, "IsoPlayer") then
        return false
    end
    dx = target:getX() - zombie:getX()
    dy = target:getY() - zombie:getY()
    return ((dx * dx) + (dy * dy)) <= (Const.ZOMBIE_TARGET_PLAYER_KEEP_RADIUS * Const.ZOMBIE_TARGET_PLAYER_KEEP_RADIUS)
end

function Internal.isPlayerImmediateThreatToNPC(
    npcDistanceSq,
    playerDistanceSq
)
    local reclaimRadius = tonumber(
        Const.ZOMBIE_NPC_PLAYER_RECLAIM_RADIUS
    ) or 2.4
    local reclaimDistanceSq = reclaimRadius * reclaimRadius

    npcDistanceSq = tonumber(npcDistanceSq) or math.huge
    playerDistanceSq = tonumber(playerDistanceSq) or math.huge

    return playerDistanceSq <= reclaimDistanceSq
        and playerDistanceSq <= npcDistanceSq
end

function Internal.shouldPreferNPCOverPlayer(npcDistanceSq, playerDistanceSq)
    local commitRadius = tonumber(Const.ZOMBIE_NPC_COMMIT_RADIUS) or 10
    local commitDistanceSq = commitRadius * commitRadius

    npcDistanceSq = tonumber(npcDistanceSq) or math.huge
    playerDistanceSq = tonumber(playerDistanceSq) or math.huge

    if npcDistanceSq < 0 or npcDistanceSq == math.huge then
        return false
    end

    -- An NPC inside the nearby commitment radius wins even when the player
    -- is closer. Outside that radius, retain the ordinary nearest-target rule.
    return npcDistanceSq <= commitDistanceSq
        or npcDistanceSq < playerDistanceSq
end

local function isFreshSneakingPlayerDetected(zombie, player, distanceSq, isRememberedTarget)
    local contactDistance
    if isRememberedTarget
        or not player.isSneaking
        or player:isSneaking() ~= true
    then
        return true
    end
    contactDistance = tonumber(Const.STEALTH_BREAK_CONTACT_DISTANCE) or 1.2
    if distanceSq <= (contactDistance * contactDistance) then
        return true
    end
    return zombie.CanSee and zombie:CanSee(player) == true
end

function Internal.findNearestLivePlayer(zombie, radius)
    local bestPlayer
    local bestDistSq = math.huge
    local seenPlayers = {}
    local limitSq = (tonumber(radius) or math.huge)
        ^ 2
    local zombieX
    local zombieY
    local zombieZ
    local currentTarget

    if not zombie then
        return nil, math.huge
    end
    zombieX = zombie:getX()
    zombieY = zombie:getY()
    zombieZ = zombie:getZ()
    currentTarget = zombie.getTarget and zombie:getTarget() or nil

    local function consider(player, allowOutsideRadius, isRememberedTarget)
        local dx
        local dy
        local distanceSq
        if not player
            or not instanceof
            or not instanceof(player, "IsoPlayer")
            or seenPlayers[player]
            or (player.isDead and player:isDead())
            or math.abs(player:getZ() - zombieZ) >= 1
        then
            return
        end
        dx = player:getX() - zombieX
        dy = player:getY() - zombieY
        distanceSq = (dx * dx) + (dy * dy)
        -- Match Stealth.IsOwnerDiscovered's detection rule: contact is a
        -- detection, while a fresh sneaking player must pass this zombie's
        -- own CanSee check. The native target is a remembered detection, so
        -- keep it eligible. This is shared by SP and the MP server's
        -- authoritative target selection.
        if not isFreshSneakingPlayerDetected(
            zombie,
            player,
            distanceSq,
            isRememberedTarget
        ) then
            return
        end
        seenPlayers[player] = true
        if (allowOutsideRadius or distanceSq <= limitSq)
            and distanceSq < bestDistSq
        then
            bestPlayer = player
            bestDistSq = distanceSq
        end
    end

    -- Keep the engine's existing player target in the comparison even if it
    -- is outside the NPC search radius. This prevents a closer NPC from
    -- displacing a player that the native zombie is already pursuing unless
    -- the NPC is genuinely nearer.
    consider(currentTarget, true, currentTarget ~= nil)
    if Core and Core.ForEachPlayer then
        Core.ForEachPlayer(function(player)
            consider(player, false)
        end)
    end
    return bestPlayer, bestDistSq
end

function Internal.findNearestLiveNPC(zombie, radius)
    local bestRecord
    local bestBody
    local bestDistSq
    local zx
    local zy
    local zz
    local limitSq
    local candidates
    local i
    local record
    local npcBody

    if not zombie then
        return nil, nil, math.huge
    end

    zx = zombie:getX()
    zy = zombie:getY()
    zz = zombie:getZ()
    limitSq = radius * radius
    bestDistSq = math.huge

    if PNC.SpatialIndex and PNC.SpatialIndex.QueryNPCs then
        candidates = PNC.SpatialIndex.QueryNPCs(zx, zy, radius)
        for i = 1, #candidates do
            record = candidates[i]
            npcBody = record and Registry.GetLiveZombie(record.id) or nil
            if npcBody
                and record.alive ~= false
                and record.presenceState == Const.PRESENCE_LIVE
                and Settings.CanZombieTargetRecord(record)
                and not (Stealth and Stealth.ShouldSuppressZombieAggro
                    and Stealth.ShouldSuppressZombieAggro(record))
                and math.abs(npcBody:getZ() - zz) < 1
            then
                local distSq = Core.DistanceSq(
                    zx,
                    zy,
                    npcBody:getX(),
                    npcBody:getY()
                )
                if distSq <= limitSq and distSq < bestDistSq then
                    bestRecord = record
                    bestBody = npcBody
                    bestDistSq = distSq
                end
            end
        end
    else
        Registry.ForEachLive(function(candidateRecord, candidateBody)
            local distSq
            if candidateBody
                and candidateRecord
                and candidateRecord.alive ~= false
                and candidateRecord.presenceState == Const.PRESENCE_LIVE
                and Settings.CanZombieTargetRecord(candidateRecord)
                and not (Stealth and Stealth.ShouldSuppressZombieAggro
                    and Stealth.ShouldSuppressZombieAggro(candidateRecord))
                and math.abs(candidateBody:getZ() - zz) < 1
            then
                distSq = Core.DistanceSq(
                    zx,
                    zy,
                    candidateBody:getX(),
                    candidateBody:getY()
                )
                if distSq <= limitSq and distSq < bestDistSq then
                    bestRecord = candidateRecord
                    bestBody = candidateBody
                    bestDistSq = distSq
                end
            end
        end)
    end

    return bestRecord, bestBody, bestDistSq
end

function Internal.canZombieAttack(zombie, now)
    local modData = Internal.getZombieModData(zombie)
    local lastAttackAt
    if not modData then
        return false
    end
    lastAttackAt = tonumber(modData.PNC_LastAttackAt or 0) or 0
    if (now - lastAttackAt) < Const.ZOMBIE_ATTACK_COOLDOWN_MS then
        return false
    end
    modData.PNC_LastAttackAt = now
    return true
end

function Internal.forceAggro(zombie, npcBody)
    local modData
    local record
    local npcId
    local now
    if not zombie or not npcBody or isForeignOwnedBody(zombie) then
        return
    end
    now = Core.Now()
    if Internal.ShouldYieldToPursuitOwner(zombie, PURSUIT_OWNER, now) then
        return false
    end
    modData = Internal.getZombieModData(zombie)
    record = Registry.FindRecordByZombie(npcBody)
    npcId = record and record.id or nil
    if record and not Settings.CanZombieTargetRecord(record) then
        Internal.clearZombieTarget(zombie)
        return false
    end
    if modData then
        modData.PNC_AggroNPCId = npcId
        modData.PNC_AggroNPCUntil = npcId
            and (now + Const.ZOMBIE_NPC_AGGRO_LEASE_MS) or nil
    end
    if npcId and not Internal.AcquirePursuitLease(
        zombie,
        PURSUIT_OWNER,
        "Hoomans",
        npcId,
        now,
        Const.ZOMBIE_NPC_AGGRO_LEASE_MS,
        100,
        "hoomans_npc"
    ) then
        return false
    end
    if npcId and ZombieAggro.Activate then
        ZombieAggro.Activate(
            zombie,
            Core.Now(),
            "forced_aggro",
            Const.ZOMBIE_NPC_AGGRO_LEASE_MS
        )
    end
    -- Preserve the attacker and action-state context installed by
    -- IsoZombie:Hit(). Clearing either during the hit frame prevents vanilla
    -- stagger from entering or exiting correctly.
    if PNC.CombatZombieReaction
        and PNC.CombatZombieReaction.IsEngineHitSettling
        and PNC.CombatZombieReaction.IsEngineHitSettling(zombie)
    then
        return
    end
    if not (isServer and isServer() == true) then
        if zombie.setTarget then
            zombie:setTarget(nil)
        end
        if zombie.setAttackedBy then
            zombie:setAttackedBy(nil)
        end
    end
    return npcId ~= nil
end
