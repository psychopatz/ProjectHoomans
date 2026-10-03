local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Stealth = PNC.Stealth
local Settings = PNC.Sandbox
local Internal = PNC.ZombieAggro.Internal
local PURSUIT_OWNER = "ProjectHoomans"

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
