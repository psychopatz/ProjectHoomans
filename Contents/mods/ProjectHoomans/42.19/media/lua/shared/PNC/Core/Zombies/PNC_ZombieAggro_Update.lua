PNC = PNC or {}
PNC.ZombieAggro = PNC.ZombieAggro or {}

local ZombieAggro = PNC.ZombieAggro
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Stealth = PNC.Stealth
local ZombieReaction = PNC.CombatZombieReaction
local Settings = PNC.Sandbox

local Internal = ZombieAggro.Internal

function ZombieAggro.ClearForNPCBody(npcBody)
    local cell
    local zombieList
    local i
    local zombie
    local target
    local forcedRecord
    local forcedBody
    if not npcBody or not getCell then
        return
    end
    ZombieAggro.ClearBiteEntriesForNPCBody(npcBody)
    cell = getCell()
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    if not zombieList then
        return
    end
    for i = zombieList:size() - 1, 0, -1 do
        zombie = zombieList:get(i)
        if zombie and (not zombie:isDead()) and (not Internal.isManagedNPCBody(zombie)) then
            target = zombie.getTarget and zombie:getTarget() or nil
            forcedRecord, forcedBody = Internal.getForcedNPCBodyTarget(zombie)
            if target == npcBody or forcedBody == npcBody then
                Internal.clearZombieTarget(zombie)
                ZombieAggro.ClearBiteEntryForZombie(zombie)
            end
        end
    end
end

function ZombieAggro.OnZombieProvoked(zombie, npcBody)
    if not zombie or not npcBody or zombie:isDead() or Internal.isManagedNPCBody(zombie) then
        return
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
    setNoLungeAttack(zombie, false)
    record.runtime = record.runtime or {}
    record.runtime.combatBlockReason = "follow_stealth_hidden"
end

local function refreshPursuitPath(zombie, npcBody, now)
    local modData = Internal.getZombieModData(zombie)
    local targetX = npcBody:getX()
    local targetY = npcBody:getY()
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
    if modData then
        modData.PNC_AggroPathAt = now
        modData.PNC_AggroPathX = targetX
        modData.PNC_AggroPathY = targetY
    end
    -- Coordinate pursuit works for an embodied NPC even though its engine type
    -- is IsoZombie. pathToCharacter may reject zombie-shaped targets.
    if zombie.pathToLocationF then
        zombie:pathToLocationF(targetX, targetY, npcBody:getZ())
    elseif zombie.pathToCharacter then
        zombie:pathToCharacter(npcBody)
    end
    if zombie.getTarget and zombie.setTarget and zombie:getTarget() ~= npcBody then
        zombie:setTarget(npcBody)
    end
    return true
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
    setNoLungeAttack(zombie, false)
    if dist < Const.ZOMBIE_BITE_DISTANCE and math.abs(zombie:getZ() - npcBody:getZ()) < 0.3 then
        if zombie.getTarget and zombie.setTarget and zombie:getTarget() ~= npcBody then
            zombie:setTarget(npcBody)
        end
        zombieSquare = zombie.getSquare and zombie:getSquare() or nil
        npcSquare = npcBody.getSquare and npcBody:getSquare() or nil
        if zombieSquare and npcSquare and not zombieSquare:isSomethingTo(npcSquare) then
            if zombie.isFacingObject and zombie:isFacingObject(npcBody, 0.3) then
                ZombieAggro.TryStartBite(zombie, npcBody, record)
            elseif zombie.faceThisObject then
                zombie:faceThisObject(npcBody)
            end
        end
    else
        refreshPursuitPath(zombie, npcBody, now)
    end
end

local function acquireNearestTarget(zombie, closerThanDistSq)
    local nearestRecord
    local nearestBody
    local nearestDistSq
    nearestRecord, nearestBody, nearestDistSq = Internal.findNearestLiveNPC(zombie, Const.ZOMBIE_AGGRO_RADIUS)
    if nearestRecord and nearestBody and (not closerThanDistSq or nearestDistSq < closerThanDistSq) then
        Internal.forceAggro(zombie, nearestBody)
        setNoLungeAttack(zombie, math.sqrt(nearestDistSq) <= Const.ZOMBIE_AGGRO_KEEP_RADIUS)
        return nearestRecord, nearestBody
    end
    setNoLungeAttack(zombie, false)
    return nil, nil
end

local function pursueNPCRecord(zombie, record, npcBody, now)
    if not record or not npcBody then
        return false
    end
    if not Settings.CanZombieTargetRecord(record) then
        Internal.clearZombieTarget(zombie)
        ZombieAggro.ClearBiteEntryForZombie(zombie, "target_protected")
        return false
    end
    if Stealth and Stealth.ShouldSuppressZombieAggro and Stealth.ShouldSuppressZombieAggro(record) then
        suppressForStealth(zombie, record)
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
    -- before vanilla's nearby-player target or NPC hits are immediately lost.
    record, npcBody = Internal.getForcedNPCBodyTarget(zombie, now)
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
        end
        return
    end
    acquireNearestTarget(zombie)
end

function ZombieAggro.Pump(now)
    local cell
    local zombieList
    local i
    local zombie

    if not Core.IsAuthority() or not getCell then
        return
    end

    if ZombieAggro.PumpBiteRecovery then
        ZombieAggro.PumpBiteRecovery(now)
    end

    cell = getCell()
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    if not zombieList then
        return
    end

    for i = zombieList:size() - 1, 0, -1 do
        zombie = zombieList:get(i)
        if zombie and (not zombie:isDead()) and (not Internal.isManagedNPCBody(zombie)) then
            processZombie(zombie, now)
        end
    end
end
