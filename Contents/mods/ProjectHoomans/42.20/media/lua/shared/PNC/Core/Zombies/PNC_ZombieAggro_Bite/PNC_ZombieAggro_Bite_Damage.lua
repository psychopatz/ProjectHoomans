local ZombieAggro = PNC.ZombieAggro
local BiteInternal = ZombieAggro.BiteInternal
local Core = PNC.Core
local Const = PNC.Const
local Health = PNC.Health
local Settings = PNC.Sandbox
local CombatDefense = PNC.CombatDefense

local function prepareImpact(entry, record, zombie, npcBody, now)
    entry.phase = "impact"
    entry.appliedDamage = true
    entry.impactAt = now
    if npcBody.setHitFromBehind and zombie.isBehind then
        npcBody:setHitFromBehind(zombie:isBehind(npcBody))
    end
    if npcBody.setPlayerAttackPosition and npcBody.testDotSide then
        npcBody:setPlayerAttackPosition(npcBody:testDotSide(zombie))
    end
    record.runtime.target = {
        kind = "zombie",
        zombieId = entry.zombieId,
        x = zombie:getX(), y = zombie:getY(), z = zombie:getZ(),
        distSq = Core.DistanceSq(
            zombie:getX(), zombie:getY(), npcBody:getX(), npcBody:getY()
        ),
    }
    record.runtime.targetKind = "zombie"
    record.runtime.combatBlockReason = "under_zombie_bite"
end

local function resolveFallback(entry, record, zombie, npcBody)
    local applied = Health.ApplyDamage(record, npcBody, {
        amount = Const.ZOMBIE_ATTACK_DAMAGE,
        type = "zombie_bite",
        attackerKind = "zombie",
        attackerZombieId = entry.zombieId,
        x = zombie:getX(), y = zombie:getY(), z = zombie:getZ(),
    })
    return applied, {
        outcome = applied and "wounded" or "blocked",
        woundType = "bite",
    }
end

local function resolveWound(entry, record, zombie, npcBody, defense)
    local wounds = PNC.NPCWounds
    if wounds and wounds.ApplyResolvedZombieAttack and defense then
        return wounds.ApplyResolvedZombieAttack(
            record, npcBody, zombie, entry.zombieId, defense
        )
    end
    if wounds and wounds.ResolveZombieAttack then
        if Settings and Settings.NPCZombieDamageModelEnabled
            and Settings.NPCZombieDamageModelEnabled()
        then
            return false, {
                outcome = "damage_resolver_unavailable",
                partId = nil,
            }
        end
        return wounds.ResolveZombieAttack(
            record, npcBody, zombie, entry.zombieId
        )
    end
    return resolveFallback(entry, record, zombie, npcBody)
end

local function resolveAttack(entry, record, zombie, npcBody, now)
    local avoided
    local defense
    if CombatDefense and CombatDefense.ResolveZombieAttack then
        avoided, defense = CombatDefense.ResolveZombieAttack(
            record, npcBody, zombie, now
        )
    end
    if avoided then
        return false, defense, defense, true
    end
    local applied, result = resolveWound(
        entry, record, zombie, npcBody, defense
    )
    return applied, result, defense, false
end

local function copyDefenseOutcome(entry, result, defense)
    entry.outcome = result and result.outcome or "blocked"
    entry.partId = result and result.partId or nil
    entry.woundType = result and result.woundType or nil
    entry.protection = result and result.protection or 0
    entry.woundChance = result and result.chance or 0
    entry.damageModel = defense and defense.damageModel == true or false
    entry.staminaRatio = defense and defense.staminaRatio or nil
    entry.safeStaminaRatio = defense and defense.safeStaminaRatio or nil
    entry.fatigueExposure = defense and defense.fatigueExposure or nil
    entry.crowdChance = defense and defense.crowdChance or nil
    entry.skillMitigation = defense and defense.skillMitigation or nil
    entry.damageChance = result and result.damageChance
        or defense and defense.damageChance or nil
    entry.damageRoll = result and result.damageRoll
        or defense and defense.damageRoll or nil
    entry.clothingBlockChance = result and result.blockChance or nil
    entry.clothingRoll = result and result.clothingRoll or nil
    entry.durabilityLoss = result and result.durabilityLoss or 0
    entry.defenseRadius = defense and defense.radius or nil
    entry.nearbyCount = defense and defense.nearbyCount or nil
    entry.fitness = defense and defense.fitness or nil
    entry.avoidChance = defense and defense.avoidChance or nil
    entry.avoidRoll = defense and defense.roll or nil
    entry.pushed = defense and defense.pushed == true or false
end

local function playImpactSound(zombie, entry, result, applied, avoided)
    if applied and zombie.playSound then
        zombie:playSound(
            result and result.woundType == "bite"
                and "ZombieBite" or "ZombieScratch"
        )
    elseif avoided and entry.pushed and zombie.playSound then
        zombie:playSound("ZombieThumpGeneric")
    end
end

function BiteInternal.ApplyBiteDamage(entry, record, zombie, npcBody, now)
    local applied
    local result
    local defense
    local avoided
    prepareImpact(entry, record, zombie, npcBody, now)
    applied, result, defense, avoided = resolveAttack(
        entry, record, zombie, npcBody, now
    )
    copyDefenseOutcome(entry, result, defense)
    playImpactSound(zombie, entry, result, applied, avoided)
    if isServer and isServer() then
        record.runtime.forceSyncEvent = "zombie_bite"
    end
    BiteInternal.SetBiteDiagnostic(record, entry, "impact")
    Core.LogRecordDebug(
        record,
        "Zombie " .. tostring(entry.zombieId)
            .. " resolved lunge on NPC " .. tostring(record.id)
            .. " outcome=" .. tostring(entry.outcome)
            .. " part=" .. tostring(entry.partId or "none")
    )
end
