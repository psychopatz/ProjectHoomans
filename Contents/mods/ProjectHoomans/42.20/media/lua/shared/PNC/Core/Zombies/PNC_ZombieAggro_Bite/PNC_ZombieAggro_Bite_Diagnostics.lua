local ZombieAggro = PNC.ZombieAggro
local BiteInternal = ZombieAggro.BiteInternal
local Core = PNC.Core
local AggroInternal = ZombieAggro.Internal

function BiteInternal.SetBiteDiagnostic(record, entry, reason)
    local zombie
    local npcBody
    local distSq
    if not record or not entry then return end
    zombie = entry.zombie
    npcBody = entry.npcBody
    distSq = zombie and npcBody and Core.DistanceSq(
        zombie:getX(), zombie:getY(), npcBody:getX(), npcBody:getY()
    ) or nil
    if zombie and AggroInternal.rememberZombieAttacker then
        AggroInternal.rememberZombieAttacker(
            record, zombie, entry.phase or "bite", Core.Now(), distSq
        )
    end
    record.runtime = record.runtime or {}
    record.runtime.lastZombieBite = {
        zombieId = entry.zombieId,
        onlineID = zombie and zombie.getOnlineID
            and tonumber(zombie:getOnlineID()) or nil,
        x = zombie and zombie:getX() or nil,
        y = zombie and zombie:getY() or nil,
        z = zombie and zombie:getZ() or nil,
        distSq = distSq,
        phase = entry.phase,
        bumpType = entry.bumpType,
        startedAt = entry.startedAt,
        impactAt = entry.impactAt,
        releaseAt = entry.releaseAt,
        finishedAt = entry.finishedAt,
        actionState = BiteInternal.ActionState(entry.zombie),
        outcome = entry.outcome,
        partId = entry.partId,
        woundType = entry.woundType,
        protection = entry.protection,
        woundChance = entry.woundChance,
        damageModel = entry.damageModel,
        staminaRatio = entry.staminaRatio,
        safeStaminaRatio = entry.safeStaminaRatio,
        fatigueExposure = entry.fatigueExposure,
        crowdChance = entry.crowdChance,
        skillMitigation = entry.skillMitigation,
        damageChance = entry.damageChance,
        damageRoll = entry.damageRoll,
        clothingBlockChance = entry.clothingBlockChance,
        clothingRoll = entry.clothingRoll,
        durabilityLoss = entry.durabilityLoss,
        defenseRadius = entry.defenseRadius,
        nearbyCount = entry.nearbyCount,
        fitness = entry.fitness,
        avoidChance = entry.avoidChance,
        avoidRoll = entry.avoidRoll,
        pushed = entry.pushed == true,
        reason = reason or entry.releaseReason,
    }
end

function BiteInternal.SignalBumpFinish(zombie)
    if not zombie then return end
    if zombie.setBumpDone then zombie:setBumpDone(true) end
    if zombie.setVariable then
        zombie:setVariable("BumpDone", true)
        zombie:setVariable("BumpAnimFinished", true)
    end
end
