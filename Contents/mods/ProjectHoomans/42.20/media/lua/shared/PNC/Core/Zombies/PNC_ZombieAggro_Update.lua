PNC = PNC or {}
PNC.ZombieAggro = PNC.ZombieAggro or {}

local ZombieAggro = PNC.ZombieAggro
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Stealth = PNC.Stealth
local ZombieReaction = PNC.CombatZombieReaction
local Settings = PNC.Sandbox
local Diagnostics = PNC.PerformanceScalingDiagnostics
local Network = PNC.Network

local Internal = ZombieAggro.Internal

local function isMultiplayerServer()
    return isServer and isServer() == true or false
end

function ZombieAggro.ClearForNPCBody(npcBody)
    local target
    local forcedRecord
    local forcedBody
    if not npcBody or not getCell then
        return
    end
    ZombieAggro.ClearBiteEntriesForNPCBody(npcBody)
    if ZombieAggro.ForEachActive then
        ZombieAggro.ForEachActive(function(zombie)
        if zombie and (not zombie:isDead()) and (not Internal.isManagedNPCBody(zombie)) then
            target = zombie.getTarget and zombie:getTarget() or nil
            forcedRecord, forcedBody = Internal.getForcedNPCBodyTarget(zombie)
            if target == npcBody or forcedBody == npcBody then
                Internal.clearZombieTarget(zombie)
                ZombieAggro.ClearBiteEntryForZombie(zombie)
            end
        end
        end)
    end
end

function ZombieAggro.OnZombieProvoked(zombie, npcBody)
    if not zombie or not npcBody or zombie:isDead() or Internal.isManagedNPCBody(zombie) then
        return
    end
    if ZombieAggro.Activate then
        ZombieAggro.Activate(zombie, Core.Now(), "provoked")
    end
    Internal.forceAggro(zombie, npcBody)
end

local function setNoLungeAttack(zombie, disabled)
    if zombie and zombie.setVariable then
        zombie:setVariable("NoLungeAttack", disabled == true)
    end
end

local function suppressForStealth(zombie, record)
    Internal.clearZombieTarget(zombie)
    ZombieAggro.ClearBiteEntryForZombie(zombie)
    -- clearZombieTarget intentionally restores the ordinary zombie default.
    -- Stealth suppression must override that default on the same frame or a
    -- stale native target can still lunge before the next aggro tick.
    setNoLungeAttack(zombie, true)
    record.runtime = record.runtime or {}
    record.runtime.combatBlockReason = Stealth
        and Stealth.IsTravelStealthActive
        and Stealth.IsTravelStealthActive(record)
        and "travel_stealth_hidden"
        or "follow_stealth_hidden"
end

local function refreshPursuitPath(zombie, npcBody, now)
    local modData = Internal.getZombieModData(zombie)
    local targetX = npcBody:getX()
    local targetY = npcBody:getY()
    local dx = targetX - zombie:getX()
    local dy = targetY - zombie:getY()
    local distanceSq = (dx * dx) + (dy * dy)
    local lastX = modData and tonumber(modData.PNC_AggroPathX) or nil
    local lastY = modData and tonumber(modData.PNC_AggroPathY) or nil
    local movedSq = lastX and lastY and Core.DistanceSq(lastX, lastY, targetX, targetY) or math.huge
    local refreshDistance = tonumber(Const.ZOMBIE_NPC_PATH_REFRESH_DISTANCE) or 0.6
    now = tonumber(now) or Core.Now()
    if modData
        and (now - (tonumber(modData.PNC_AggroPathAt) or 0)) < (tonumber(Const.ZOMBIE_NPC_PATH_REFRESH_MS) or 350)
        and movedSq < (refreshDistance * refreshDistance)
    then
        return false
    end
    if ZombieAggro.ConsumePathRequestBudget
        and not ZombieAggro.ConsumePathRequestBudget()
    then
        if Diagnostics then
            Diagnostics.Increment(
                "ZombieAggro.PathRequestsDeferred"
            )
        end
        return false
    end
    if modData then
        modData.PNC_AggroPathAt = now
        modData.PNC_AggroPathX = targetX
        modData.PNC_AggroPathY = targetY
    end
    -- This is the legacy singleplayer pursuit handoff. Keep the selected NPC
    -- as the native movement target for WalkTowardState; MP never calls this
    -- function because its owner receives a separate movement directive.
    if zombie.setTarget
        and (not zombie.getTarget or zombie:getTarget() ~= npcBody)
    then
        zombie:setTarget(npcBody)
        if distanceSq > (3.5 * 3.5) and zombie.spotted then
            zombie:spotted(npcBody, false)
        end
    end
    local canSee = true
    if zombie.CanSee then
        canSee = zombie:CanSee(npcBody) == true
    end
    if canSee and zombie.pathToCharacter then
        zombie:pathToCharacter(npcBody)
        if Diagnostics then
            Diagnostics.Increment("ZombieAggro.PathRequests")
        end
    elseif zombie.pathToLocationF then
        zombie:pathToLocationF(targetX, targetY, npcBody:getZ())
        if Diagnostics then
            Diagnostics.Increment("ZombieAggro.PathRequests")
        end
    end
    return true
end

local function incrementDiagnostic(name, amount)
    if Diagnostics and Diagnostics.Increment then
        Diagnostics.Increment(name, amount)
    end
end

local function isMPDirectiveServer()
    return isMultiplayerServer()
        and Network
        and Network.GetZombieOnlineID
        and Network.Internal
        and Network.Internal.SendToNearbyPlayers
end

local function clearMPTargetDirective(zombie, now)
    local modData
    local zombieOnlineID
    local revision
    local payload
    local sent
    if not isMPDirectiveServer() or not zombie then
        return 0
    end
    modData = Internal.getZombieModData(zombie)
    if not modData or modData.PNC_MPAggroDirectiveNPCId == nil then
        return 0
    end
    zombieOnlineID = Network.GetZombieOnlineID(zombie)
    revision = (tonumber(modData.PNC_MPAggroDirectiveRevision) or 0) + 1
    payload = {
        active = false,
        zombieOnlineID = zombieOnlineID,
        npcId = modData.PNC_MPAggroDirectiveNPCId,
        x = tonumber(modData.PNC_MPAggroDirectiveX),
        y = tonumber(modData.PNC_MPAggroDirectiveY),
        z = tonumber(modData.PNC_MPAggroDirectiveZ),
        expiresAt = tonumber(now) or Core.Now(),
        revision = revision,
    }
    sent = 0
    if zombieOnlineID ~= nil then
        sent = Network.Internal.SendToNearbyPlayers(
            zombie,
            nil,
            Const.CMD_ZOMBIE_PURSUIT,
            payload
        )
    end
    modData.PNC_MPAggroDirectiveRevision = revision
    modData.PNC_MPAggroDirectiveNPCId = nil
    modData.PNC_MPAggroDirectiveLastSentAt = nil
    modData.PNC_MPAggroDirectiveX = nil
    modData.PNC_MPAggroDirectiveY = nil
    modData.PNC_MPAggroDirectiveZ = nil
    if sent > 0 then
        incrementDiagnostic("ZombieAggro.MPDirectiveCleared", sent)
    end
    return sent
end

local function publishMPTargetDirective(zombie, record, npcBody, now)
    local modData
    local zombieOnlineID
    local npcId
    local targetX
    local targetY
    local targetZ
    local previousId
    local previousX
    local previousY
    local targetChanged
    local movedSq
    local sendAt
    local sent
    local payload
    if not isMPDirectiveServer() or not zombie or not record or not npcBody then
        return 0
    end
    modData = Internal.getZombieModData(zombie)
    zombieOnlineID = Network.GetZombieOnlineID(zombie)
    npcId = record.id ~= nil and tostring(record.id) or nil
    targetX = tonumber(npcBody:getX())
    targetY = tonumber(npcBody:getY())
    targetZ = tonumber(npcBody:getZ())
    if not modData or zombieOnlineID == nil or not npcId
        or targetX == nil or targetY == nil or targetZ == nil
    then
        return 0
    end
    previousId = modData.PNC_MPAggroDirectiveNPCId
    previousX = tonumber(modData.PNC_MPAggroDirectiveX)
    previousY = tonumber(modData.PNC_MPAggroDirectiveY)
    targetChanged = tostring(previousId or "") ~= npcId
    movedSq = previousX and previousY
        and Core.DistanceSq(previousX, previousY, targetX, targetY)
        or math.huge
    now = tonumber(now) or Core.Now()
    sendAt = tonumber(modData.PNC_MPAggroDirectiveLastSentAt) or 0
    if not targetChanged
        and now - sendAt < (tonumber(Const.ZOMBIE_NPC_DIRECTIVE_SEND_MS) or 400)
        and movedSq < ((tonumber(Const.ZOMBIE_NPC_PATH_REFRESH_DISTANCE) or 0.6) ^ 2)
    then
        return 0
    end
    if targetChanged then
        modData.PNC_MPAggroDirectiveRevision =
            (tonumber(modData.PNC_MPAggroDirectiveRevision) or 0) + 1
    end
    payload = {
        active = true,
        zombieOnlineID = zombieOnlineID,
        npcId = npcId,
        x = targetX,
        y = targetY,
        z = targetZ,
        expiresAt = now + (tonumber(Const.ZOMBIE_NPC_DIRECTIVE_TTL_MS) or 1100),
        revision = tonumber(modData.PNC_MPAggroDirectiveRevision) or 1,
    }
    sent = Network.Internal.SendToNearbyPlayers(
        zombie,
        npcBody,
        Const.CMD_ZOMBIE_PURSUIT,
        payload
    )
    modData.PNC_MPAggroDirectiveNPCId = npcId
    modData.PNC_MPAggroDirectiveX = targetX
    modData.PNC_MPAggroDirectiveY = targetY
    modData.PNC_MPAggroDirectiveZ = targetZ
    if sent > 0 then
        modData.PNC_MPAggroDirectiveLastSentAt = now
        incrementDiagnostic("ZombieAggro.MPDirectiveSent", sent)
    end
    return sent
end

local function pursueForcedTarget(zombie, npcBody, record, now)
    local distSq
    local dist
    local zombieSquare
    local npcSquare
    if npcBody.setZombiesDontAttack then
        npcBody:setZombiesDontAttack(false)
    end
    distSq = Core.DistanceSq(zombie:getX(), zombie:getY(), npcBody:getX(), npcBody:getY())
    dist = math.sqrt(distSq)
    if Internal.rememberZombieAttacker then
        Internal.rememberZombieAttacker(
            record,
            zombie,
            dist < Const.ZOMBIE_BITE_DISTANCE
                and "bite_range" or "pursuit",
            now,
            distSq
        )
    end
    if isMultiplayerServer() then
        -- In MP the server selects the target, while the client that owns
        -- this zombie performs native movement. Never put the NPC shell in
        -- native combat slots; only replicate this movement directive.
        setNoLungeAttack(zombie, true)
        publishMPTargetDirective(zombie, record, npcBody, now)
    else
        -- Restore the prior SP state machine. The client-side SP controller
        -- owns the abstract NPC damage gate and this flag is not its target
        -- selection mechanism.
        setNoLungeAttack(zombie, false)
    end
    if isMultiplayerServer() then
        if zombie.setTarget then zombie:setTarget(nil) end
        if zombie.setAttackedBy then zombie:setAttackedBy(nil) end
        if zombie.setTargetSeenTime then zombie:setTargetSeenTime(0) end
        if zombie.clearAggroList then zombie:clearAggroList() end
    end
    if dist < Const.ZOMBIE_BITE_DISTANCE and math.abs(zombie:getZ() - npcBody:getZ()) < 0.3 then
        zombieSquare = zombie.getSquare and zombie:getSquare() or nil
        npcSquare = npcBody.getSquare and npcBody:getSquare() or nil
        if zombieSquare and npcSquare and not zombieSquare:isSomethingTo(npcSquare) then
            if zombie.isFacingObject and zombie:isFacingObject(npcBody, 0.3) then
                ZombieAggro.TryStartBite(zombie, npcBody, record)
            elseif zombie.faceThisObject then
                zombie:faceThisObject(npcBody)
            end
        end
    elseif not isMultiplayerServer() then
        -- SP/local authority owns the native zombie path. In MP the owning
        -- client performs native pursuit while this server code owns only the
        -- forced-target lease, bite validation, and damage.
        if zombie.isUseless and zombie.setUseless
            and zombie:isUseless()
        then
            -- Match Bandits for the active ordinary-zombie lane. Do this only
            -- while a pursuit is active; distant zombies retain engine tiering.
            zombie:setUseless(false)
        end
        refreshPursuitPath(zombie, npcBody, now)
    end
end

local function acquireNearestTarget(zombie, closerThanDistSq)
    local nearestRecord
    local nearestBody
    local nearestDistSq
    local nearestPlayer
    local nearestPlayerDistSq
    nearestRecord, nearestBody, nearestDistSq = Internal.findNearestLiveNPC(zombie, Const.ZOMBIE_AGGRO_RADIUS)
    nearestPlayer, nearestPlayerDistSq = Internal.findNearestLivePlayer(
        zombie,
        Const.ZOMBIE_AGGRO_RADIUS
    )
    if nearestPlayer and nearestPlayerDistSq <= nearestDistSq then
        setNoLungeAttack(zombie, false)
        return nil, nil
    end
    if nearestRecord and nearestBody and (not closerThanDistSq or nearestDistSq < closerThanDistSq) then
        Internal.forceAggro(zombie, nearestBody)
        if isMultiplayerServer() then
            setNoLungeAttack(zombie, true)
        else
            setNoLungeAttack(
                zombie,
                math.sqrt(nearestDistSq) <= Const.ZOMBIE_AGGRO_KEEP_RADIUS
            )
        end
        return nearestRecord, nearestBody
    end
    setNoLungeAttack(zombie, false)
    return nil, nil
end

local function pursueNPCRecord(zombie, record, npcBody, now)
    if not record or not npcBody then
        clearMPTargetDirective(zombie, now)
        return false
    end
    if not Settings.CanZombieTargetRecord(record) then
        Internal.clearZombieTarget(zombie)
        clearMPTargetDirective(zombie, now)
        ZombieAggro.ClearBiteEntryForZombie(zombie, "target_protected")
        return false
    end
    if Stealth and Stealth.ShouldSuppressZombieAggro and Stealth.ShouldSuppressZombieAggro(record) then
        suppressForStealth(zombie, record)
        clearMPTargetDirective(zombie, now)
    else
        pursueForcedTarget(zombie, npcBody, record, now)
    end
    return true
end

local function processZombie(zombie, now)
    local target
    local record
    local npcBody
    local hitSettling
    local playerDistSq
    local nearestPlayer
    local nearestPlayerDistSq
    local forcedNPCDistSq
    if ZombieReaction and ZombieReaction.Pump then
        ZombieReaction.Pump(zombie, now)
    end
    hitSettling = ZombieReaction
        and ZombieReaction.IsEngineHitSettling
        and ZombieReaction.IsEngineHitSettling(zombie, now)
        or false
    if hitSettling then
        -- The engine owns hit/stagger recovery during this short window.
        return
    end
    if ZombieAggro.UpdateBiteState(zombie, now) then
        -- Bite flow owns the zombie while the bite is active.
        return
    end

    -- A recent NPC provocation wins for a bounded lease. This must be checked
    -- before vanilla's nearby-player target or NPC hits are immediately lost,
    -- but a genuinely nearer player still wins the ordinary movement choice.
    record, npcBody = Internal.getForcedNPCBodyTarget(zombie, now)
    if isMultiplayerServer() and record and npcBody then
        nearestPlayer, nearestPlayerDistSq = Internal.findNearestLivePlayer(
            zombie,
            Const.ZOMBIE_AGGRO_RADIUS
        )
        forcedNPCDistSq = Core.DistanceSq(
            zombie:getX(),
            zombie:getY(),
            npcBody:getX(),
            npcBody:getY()
        )
        if nearestPlayer and nearestPlayerDistSq <= forcedNPCDistSq then
            Internal.clearZombieTarget(zombie)
            clearMPTargetDirective(zombie, now)
            acquireNearestTarget(zombie)
            return
        end
    end
    if pursueNPCRecord(zombie, record, npcBody, now) then
        return
    end

    target = zombie.getTarget and zombie:getTarget() or nil
    if Core.IsManagedNPCBody(target) then
        Internal.forceAggro(zombie, target)
        record, npcBody = Internal.getForcedNPCBodyTarget(zombie, now)
        pursueNPCRecord(zombie, record, npcBody, now)
        return
    end
    if Internal.isCloseLivePlayerTarget(zombie, target) then
        playerDistSq = Core.DistanceSq(zombie:getX(), zombie:getY(), target:getX(), target:getY())
        record, npcBody = acquireNearestTarget(zombie, playerDistSq)
        if not pursueNPCRecord(zombie, record, npcBody, now) then
            setNoLungeAttack(zombie, false)
            clearMPTargetDirective(zombie, now)
        end
        return
    end
    record, npcBody = acquireNearestTarget(zombie)
    if isMultiplayerServer() then
        if record and npcBody then
            publishMPTargetDirective(zombie, record, npcBody, now)
        else
            clearMPTargetDirective(zombie, now)
        end
    end
end

function ZombieAggro.Pump(now)
    if not Core.IsAuthority() then
        return
    end

    if ZombieAggro.PumpBiteRecovery then
        ZombieAggro.PumpBiteRecovery(now)
    end

    if ZombieAggro.RefreshActiveSet then
        ZombieAggro.RefreshActiveSet(now, false)
    end
    if ZombieAggro.PumpActiveSet then
        return ZombieAggro.PumpActiveSet(now, processZombie)
    end
    return 0
end
