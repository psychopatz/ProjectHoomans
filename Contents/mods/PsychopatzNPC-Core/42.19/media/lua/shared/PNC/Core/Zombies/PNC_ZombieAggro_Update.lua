PNC = PNC or {}
PNC.ZombieAggro = PNC.ZombieAggro or {}

local ZombieAggro = PNC.ZombieAggro
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Stealth = PNC.Stealth
local ZombieReaction = PNC.CombatZombieReaction

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

local function pursueForcedTarget(zombie, npcBody, record)
    local distSq
    local dist
    local zombieSquare
    local npcSquare
    distSq = Core.DistanceSq(zombie:getX(), zombie:getY(), npcBody:getX(), npcBody:getY())
    dist = math.sqrt(distSq)
    setNoLungeAttack(zombie, dist <= Const.ZOMBIE_AGGRO_KEEP_RADIUS)
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
    elseif zombie.pathToCharacter then
        zombie:pathToCharacter(npcBody)
    elseif zombie.pathToLocation then
        zombie:pathToLocation(npcBody:getX(), npcBody:getY(), npcBody:getZ())
    end
end

local function acquireNearestTarget(zombie)
    local nearestRecord
    local nearestBody
    local nearestDistSq
    nearestRecord, nearestBody, nearestDistSq = Internal.findNearestLiveNPC(zombie, Const.ZOMBIE_AGGRO_RADIUS)
    if nearestRecord and nearestBody then
        Internal.forceAggro(zombie, nearestBody)
        setNoLungeAttack(zombie, math.sqrt(nearestDistSq) <= Const.ZOMBIE_AGGRO_KEEP_RADIUS)
        return
    end
    setNoLungeAttack(zombie, false)
end

local function processZombie(zombie, now)
    local target
    local record
    local npcBody
    local hitSettling
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

    target = zombie.getTarget and zombie:getTarget() or nil
    if Internal.isCloseLivePlayerTarget(zombie, target) then
        setNoLungeAttack(zombie, false)
        return
    end
    if Core.IsManagedNPCBody(target) then
        Internal.forceAggro(zombie, target)
    end

    record, npcBody = Internal.getForcedNPCBodyTarget(zombie)
    if not record or not npcBody then
        acquireNearestTarget(zombie)
        return
    end
    if Stealth and Stealth.ShouldSuppressZombieAggro and Stealth.ShouldSuppressZombieAggro(record) then
        suppressForStealth(zombie, record)
        return
    end
    pursueForcedTarget(zombie, npcBody, record)
end

function ZombieAggro.Pump(now)
    local cell
    local zombieList
    local i
    local zombie

    if not Core.IsAuthority() or not getCell then
        return
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
