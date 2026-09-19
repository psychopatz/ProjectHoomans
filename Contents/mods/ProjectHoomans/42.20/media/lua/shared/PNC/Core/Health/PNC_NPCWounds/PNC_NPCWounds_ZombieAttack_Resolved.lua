PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal

local function logAttack(record, status, reason, attackerId, partId, woundType, damage)
    if Internal.LogZombieAttackDebug then
        Internal.LogZombieAttackDebug(
            record,
            "resolved",
            status,
            reason,
            attackerId,
            partId,
            woundType,
            damage
        )
    end
end

local function resolveDamageModel(npcBody, defenseResult)
    local part = defenseResult and defenseResult.part or nil
    local initialWoundType = tostring(
        defenseResult and defenseResult.damageType or "scratch"
    )
    local woundType = initialWoundType
    local protection = 0
    local clothingResult
    if not part or not Internal.WoundStats[woundType] then
        return nil, {
            outcome = "invalid_resolved_attack",
            partId = defenseResult
                and defenseResult.partId or nil,
        }
    end
    if defenseResult and defenseResult.damageModel == true then
        clothingResult = Wounds.ResolveZombieClothing(
            npcBody,
            part,
            initialWoundType
        )
        protection = tonumber(clothingResult.protection) or 0
        if clothingResult.blocked then
            return nil, {
                outcome = clothingResult.outcome,
                partId = part.id,
                initialWoundType = initialWoundType,
                protection = protection,
                blockChance = clothingResult.blockChance,
                clothingRoll = clothingResult.roll,
                durabilityLoss =
                    clothingResult.durabilityLoss,
                conditionBefore =
                    clothingResult.conditionBefore,
                conditionAfter =
                    clothingResult.conditionAfter,
                damageChance = defenseResult.damageChance,
                damageRoll = defenseResult.damageRoll,
            }
        end
        woundType =
            clothingResult.finalWoundType or initialWoundType
    else
        protection = tonumber(
            defenseResult and defenseResult.protection
        ) or 0
    end
    return {
        part = part,
        initialWoundType = initialWoundType,
        woundType = woundType,
        protection = protection,
        clothingResult = clothingResult,
    }
end

local function buildResolvedResult(
    record,
    wound,
    attack,
    defenseResult
)
    local clothingResult = attack.clothingResult
    return {
        outcome = "wounded",
        partId = attack.part.id,
        woundType = wound.type,
        initialWoundType = attack.initialWoundType,
        protection = attack.protection,
        blockChance = clothingResult
            and clothingResult.blockChance or nil,
        clothingRoll = clothingResult
            and clothingResult.roll or nil,
        durabilityLoss = clothingResult
            and clothingResult.durabilityLoss or 0,
        conditionBefore = clothingResult
            and clothingResult.conditionBefore or nil,
        conditionAfter = clothingResult
            and clothingResult.conditionAfter or nil,
        chance = defenseResult
            and (
                defenseResult.damageChance
                or defenseResult.avoidChance
            ) or nil,
        roll = defenseResult
            and (
                defenseResult.damageRoll
                or defenseResult.roll
            ) or nil,
        damageChance = defenseResult
            and defenseResult.damageChance or nil,
        damageRoll = defenseResult
            and defenseResult.damageRoll or nil,
        infected = Wounds.HasActiveInfection(record),
    }
end

function Wounds.ApplyResolvedZombieAttack(
    record,
    npcBody,
    attacker,
    attackerZombieId,
    defenseResult
)
    if not Internal.HasServerAuthority() then
        logAttack(record, "rejected", "not_authority", attackerZombieId)
        return false, { outcome = "not_authority" }
    end
    if not Internal.IsLiveZombieTarget(record, npcBody) then
        logAttack(record, "rejected", "target_invalid", attackerZombieId)
        return false, { outcome = "target_invalid" }
    end
    local attack, result = resolveDamageModel(npcBody, defenseResult)
    if not attack then
        logAttack(record, "rejected", result and result.outcome,
            attackerZombieId, result and result.partId,
            result and result.woundType)
        return false, result
    end
    local rejectedResult = {
        outcome = "damage_rejected",
        partId = attack.part.id,
        initialWoundType = attack.initialWoundType,
        woundType = attack.woundType,
        protection = attack.protection,
        damageChance =
            defenseResult and defenseResult.damageChance or nil,
        damageRoll =
            defenseResult and defenseResult.damageRoll or nil,
    }
    local wound, failure, damage = Internal.ApplyZombieWoundDamage(
        record,
        npcBody,
        attacker,
        attackerZombieId,
        attack.part,
        attack.woundType,
        rejectedResult
    )
    if not wound then
        logAttack(record, "rejected", failure and failure.outcome,
            attackerZombieId, attack.part.id, attack.woundType)
        return false, failure
    end
    Internal.RecordZombieDamage(record, attacker, attackerZombieId)
    Internal.EmitZombieDamageHook(
        record,
        npcBody,
        attacker,
        damage,
        wound,
        attackerZombieId,
        "npc_zombie_attack_resolved"
    )
    logAttack(record, "applied", "wounded", attackerZombieId,
        attack.part.id, wound.type, damage)
    return true, buildResolvedResult(
        record,
        wound,
        attack,
        defenseResult
    )
end

return Wounds
