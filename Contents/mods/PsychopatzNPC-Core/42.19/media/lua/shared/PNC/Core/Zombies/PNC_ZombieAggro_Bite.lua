PNC = PNC or {}
PNC.ZombieAggro = PNC.ZombieAggro or {}

local ZombieAggro = PNC.ZombieAggro
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Health = PNC.Health
local Equipment = PNC.Equipment

local State = ZombieAggro.State
local Internal = ZombieAggro.Internal

local function getBiteEntry(zombieId)
    return zombieId and State.bites and State.bites[zombieId] or nil
end

local function actionState(zombie)
    return zombie and zombie.getActionStateName and tostring(zombie:getActionStateName() or "") or ""
end

local function setBiteDiagnostic(record, entry, reason)
    if not record or not entry then
        return
    end
    record.runtime = record.runtime or {}
    record.runtime.lastZombieBite = {
        zombieId = entry.zombieId,
        phase = entry.phase,
        bumpType = entry.bumpType,
        startedAt = entry.startedAt,
        impactAt = entry.impactAt,
        releaseAt = entry.releaseAt,
        finishedAt = entry.finishedAt,
        actionState = actionState(entry.zombie),
        reason = reason or entry.releaseReason,
    }
end

local function signalBumpFinish(zombie)
    if not zombie then
        return
    end
    if zombie.setBumpDone then
        zombie:setBumpDone(true)
    end
    if zombie.setVariable then
        zombie:setVariable("BumpDone", true)
        zombie:setVariable("BumpAnimFinished", true)
    end
end

local function finalizeRelease(zombieId, entry, now, reason)
    local zombie = entry and entry.zombie or nil
    local npcBody = entry and entry.npcBody or nil
    local record = entry and Registry.Get(entry.npcId) or nil
    if npcBody and npcBody.setZombiesDontAttack then
        npcBody:setZombiesDontAttack(false)
    end
    signalBumpFinish(zombie)
    if zombie and zombie.setBumpType then
        zombie:setBumpType("")
    end
    if zombie and zombie.setBumpedChr then
        pcall(zombie.setBumpedChr, zombie, nil)
    end
    if zombie and zombie.setVariable then
        zombie:setVariable("PNCZombieBitingNPC", false)
    end
    if entry then
        entry.phase = "finished"
        entry.finishedAt = now
        entry.releaseReason = reason or entry.releaseReason
        setBiteDiagnostic(record, entry, entry.releaseReason)
    end
    State.bites[zombieId] = nil
end

local function beginRelease(zombieId, npcBody, reason, now)
    local entry
    local record
    if not zombieId or not State.bites then
        return false
    end
    entry = State.bites[zombieId]
    if not entry then
        return false
    end
    if entry.phase == "release" then
        return true
    end
    now = tonumber(now) or Core.Now()
    entry.phase = "release"
    entry.releaseAt = now
    entry.releaseDeadline = now + (tonumber(Const.BITE_RELEASE_TIMEOUT_MS) or 650)
    entry.releaseReason = reason or "complete"
    entry.npcBody = entry.npcBody or npcBody
    signalBumpFinish(entry.zombie)
    if entry.broadcastClear ~= true and PNC.Network and PNC.Network.BroadcastZombieBite then
        entry.broadcastClear = true
        PNC.Network.BroadcastZombieBite(entry.zombie, entry.npcBody, entry.npcId, "clear", entry.bumpType)
    end
    record = Registry.Get(entry.npcId)
    setBiteDiagnostic(record, entry, entry.releaseReason)
    return true
end

function ZombieAggro.ClearBiteEntryForZombie(zombie, reason)
    local zombieId = Internal.ensureZombieID(zombie)
    return beginRelease(zombieId, nil, reason or "cleared", Core.Now())
end

function ZombieAggro.ClearBiteEntriesForNPCBody(npcBody, reason)
    local zombieId
    local entry
    if not npcBody or not State.bites then
        return
    end
    for zombieId, entry in pairs(State.bites) do
        if entry and entry.npcBody == npcBody then
            beginRelease(zombieId, npcBody, reason or "npc_body_cleared", Core.Now())
        end
    end
end

function ZombieAggro.TryStartBite(zombie, npcBody, record)
    local zombieId
    local asn
    local bumpType
    local now
    local entry

    if not zombie or not npcBody or not record then
        return false
    end
    zombieId = Internal.ensureZombieID(zombie)
    if not zombieId then
        return false
    end
    entry = getBiteEntry(zombieId)
    if entry then
        return true
    end
    asn = actionState(zombie)
    bumpType = zombie.getBumpType and zombie:getBumpType() or ""
    if asn == "staggerback" or asn == "bumped" or bumpType == "Bite" or bumpType == "BiteLow" then
        return false
    end
    now = Core.Now()
    if Internal.canZombieAttack and not Internal.canZombieAttack(zombie, now) then
        return false
    end
    bumpType = ((npcBody.isProne and npcBody:isProne())
        or (npcBody.isCrawling and npcBody:isCrawling()))
        and "BiteLow" or "Bite"
    if npcBody.setZombiesDontAttack then
        npcBody:setZombiesDontAttack(false)
    end
    if zombie.setTarget then
        zombie:setTarget(npcBody)
    end
    if zombie.setBumpedChr then
        zombie:setBumpedChr(npcBody)
    end
    if zombie.setBumpDone then
        zombie:setBumpDone(false)
    end
    if zombie.setVariable then
        zombie:setVariable("PNCZombieBitingNPC", true)
        zombie:setVariable("BumpDone", false)
        zombie:setVariable("BumpAnimFinished", false)
    end
    if zombie.setBumpType then
        zombie:setBumpType(bumpType)
    end

    entry = {
        zombieId = zombieId,
        npcId = record.id,
        zombie = zombie,
        npcBody = npcBody,
        bumpType = bumpType,
        phase = "windup",
        startedAt = now,
        applyAt = now + Const.ZOMBIE_BITE_APPLY_DELAY_MS,
        clearAt = now + Const.ZOMBIE_BITE_CLEAR_DELAY_MS,
        appliedDamage = false,
        broadcastClear = false,
    }
    State.bites[zombieId] = entry
    setBiteDiagnostic(record, entry, "started")
    if PNC.Network and PNC.Network.BroadcastZombieBite then
        PNC.Network.BroadcastZombieBite(zombie, npcBody, record.id, "start", bumpType)
    end
    Core.LogRecordDebug(record, "Zombie " .. tostring(zombieId) .. " started bite on NPC " .. tostring(record.id))
    return true
end

local function applyBiteDamage(entry, record, zombie, npcBody, now)
    local teeth
    entry.phase = "impact"
    entry.appliedDamage = true
    entry.impactAt = now
    if ZombRand(4) == 1 and zombie.playSound then
        zombie:playSound("ZombieBite")
    elseif zombie.playSound then
        zombie:playSound("ZombieScratch")
    end
    if Equipment and Equipment.CreateItem then
        teeth = Equipment.CreateItem("Base.RollingPin")
    end
    if npcBody.setHitFromBehind and zombie.isBehind then
        npcBody:setHitFromBehind(zombie:isBehind(npcBody))
    end
    if npcBody.setPlayerAttackPosition and npcBody.testDotSide then
        npcBody:setPlayerAttackPosition(npcBody:testDotSide(zombie))
    end
    record.runtime.target = {
        kind = "zombie",
        zombieId = entry.zombieId,
        x = zombie:getX(),
        y = zombie:getY(),
        z = zombie:getZ(),
        distSq = Core.DistanceSq(zombie:getX(), zombie:getY(), npcBody:getX(), npcBody:getY()),
    }
    record.runtime.targetKind = "zombie"
    record.runtime.combatBlockReason = "under_zombie_bite"
    if teeth and npcBody.Hit then
        pcall(function()
            npcBody:Hit(teeth, zombie, 1.01, false, 1, false)
        end)
    end
    Health.ApplyDamage(record, npcBody, {
        amount = Const.ZOMBIE_ATTACK_DAMAGE,
        type = "zombie_bite",
        attackerKind = "zombie",
        x = zombie:getX(),
        y = zombie:getY(),
        z = zombie:getZ(),
    })
    if isServer and isServer() then
        record.runtime.forceSyncEvent = "zombie_bite"
    end
    setBiteDiagnostic(record, entry, "impact")
    Core.LogRecordDebug(record, "Zombie " .. tostring(entry.zombieId) .. " applied bite to NPC " .. tostring(record.id))
end

function ZombieAggro.UpdateBiteState(zombie, now)
    local zombieId
    local entry
    local record
    local npcBody
    local dist
    local asn
    if not zombie then
        return false
    end
    zombieId = Internal.ensureZombieID(zombie)
    entry = getBiteEntry(zombieId)
    if not entry then
        return false
    end
    now = tonumber(now) or Core.Now()
    record = Registry.Get(entry.npcId)
    npcBody = entry.npcBody
    if zombie.isDead and zombie:isDead() then
        beginRelease(zombieId, npcBody, "attacker_dead", now)
        return true
    end
    if entry.phase == "release" then
        signalBumpFinish(zombie)
        asn = actionState(zombie)
        setBiteDiagnostic(record, entry, entry.releaseReason)
        if (asn ~= "bumped" and (now - (tonumber(entry.releaseAt) or now)) >= 35)
            or now >= (tonumber(entry.releaseDeadline) or now)
        then
            finalizeRelease(zombieId, entry, now, asn == "bumped" and "release_timeout" or entry.releaseReason)
        end
        return true
    end
    if not record or not npcBody or record.alive == false
        or record.presenceState ~= Const.PRESENCE_LIVE
        or (npcBody.isDead and npcBody:isDead())
    then
        beginRelease(zombieId, npcBody, "target_invalid", now)
        return true
    end
    dist = Core.Distance(zombie:getX(), zombie:getY(), npcBody:getX(), npcBody:getY())
    if dist > (Const.ZOMBIE_BITE_DISTANCE * 1.35) then
        beginRelease(zombieId, npcBody, "target_out_of_range", now)
        return true
    end
    if entry.appliedDamage ~= true and now >= (tonumber(entry.applyAt) or now) then
        applyBiteDamage(entry, record, zombie, npcBody, now)
    end
    if now >= (tonumber(entry.clearAt) or now) then
        beginRelease(zombieId, npcBody, "complete", now)
    end
    return true
end

function ZombieAggro.PumpBiteRecovery(now)
    local zombieId
    local entry
    local zombie
    local releaseAt
    now = tonumber(now) or Core.Now()
    for zombieId, entry in pairs(State.bites or {}) do
        zombie = entry and entry.zombie or nil
        if not zombie then
            finalizeRelease(zombieId, entry, now, "attacker_missing")
        elseif (zombie.isDead and zombie:isDead())
            or (zombie.getSquare and zombie:getSquare() == nil)
        then
            beginRelease(zombieId, entry.npcBody, "attacker_lost", now)
            releaseAt = tonumber(entry.releaseAt) or now
            signalBumpFinish(zombie)
            if (now - releaseAt) >= 35 or now >= (tonumber(entry.releaseDeadline) or now) then
                finalizeRelease(zombieId, entry, now, "attacker_lost")
            end
        elseif entry.phase == "release" then
            ZombieAggro.UpdateBiteState(zombie, now)
        end
    end
end
