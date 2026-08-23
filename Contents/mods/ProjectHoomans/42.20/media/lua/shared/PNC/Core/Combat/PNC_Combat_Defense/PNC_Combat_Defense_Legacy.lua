local Defense = PNC.CombatDefense
local Internal = Defense.Internal
local Const = PNC.Const
local Skills = PNC.Skills
local Wounds = PNC.NPCWounds

local function baseAvoidChance(fitness)
    if fitness >= 2 then
        return (tonumber(Const.NPC_ZOMBIE_DEFENSE_FITNESS_TWO_CHANCE)
                or 0.98)
            + ((fitness - 2)
                * (tonumber(Const.NPC_ZOMBIE_DEFENSE_HIGH_FITNESS_STEP)
                    or 0.0015))
    end
    return (tonumber(Const.NPC_ZOMBIE_DEFENSE_FITNESS_BASE) or 0.90)
        + (fitness
            * (tonumber(Const.NPC_ZOMBIE_DEFENSE_FITNESS_STEP) or 0.04))
end

function Defense.CalculateAvoidChance(
    record, npcBody, damageType, nearbyCount, part
)
    local fitness = Skills and Skills.GetLevel
        and Skills.GetLevel(record, "Fitness") or 0
    local protection = Wounds and Wounds.GetProtection
        and Wounds.GetProtection(npcBody, part, damageType) or 0
    local crowdPenalty
    local rawChance
    local finalChance
    fitness = Internal.Clamp(fitness, 0, 10)
    nearbyCount = math.max(1, math.floor(tonumber(nearbyCount) or 1))
    crowdPenalty = math.max(
        tonumber(Const.NPC_ZOMBIE_DEFENSE_MIN_CROWD_PENALTY) or 0.075,
        (tonumber(Const.NPC_ZOMBIE_DEFENSE_CROWD_PENALTY) or 0.14)
            - (fitness * 0.005)
    )
    rawChance = baseAvoidChance(fitness)
        - (math.max(0, nearbyCount - 1) * crowdPenalty)
    rawChance = Internal.Clamp(
        rawChance,
        tonumber(Const.NPC_ZOMBIE_DEFENSE_MIN_CHANCE) or 0.05,
        tonumber(Const.NPC_ZOMBIE_DEFENSE_MAX_CHANCE) or 0.995
    )
    finalChance = 1
        - ((1 - rawChance)
            * (1 - Internal.Clamp(protection, 0, 100) / 100))
    return Internal.Clamp(
        finalChance,
        tonumber(Const.NPC_ZOMBIE_DEFENSE_MIN_CHANCE) or 0.05,
        tonumber(Const.NPC_ZOMBIE_DEFENSE_MAX_CHANCE) or 0.995
    ), Internal.Clamp(protection, 0, 100), fitness, rawChance
end

local function storeLegacyResult(
    state, part, damageType, fitness, protection,
    mobilityChance, chance, roll, avoided, pushRoll, pushed, now
)
    state.damageType = damageType
    state.partId = part and part.id or nil
    state.fitness = fitness
    state.protection = protection
    state.mobilityChance = mobilityChance
    state.avoidChance = chance
    state.roll = roll
    state.avoided = avoided
    state.pushRoll = pushRoll
    state.pushed = pushed
    state.lastResolvedAt = now
    state.outcome = avoided
        and (pushed and "avoided_push" or "avoided") or "hit"
end

function Internal.ResolveLegacyAttack(record, npcBody, zombie, now)
    local state = Defense.Refresh(record, npcBody, now)
    local nearbyCount
    local part
    local damageType
    local chance
    local protection
    local fitness
    local mobilityChance
    local roll
    local avoided
    local pushRoll
    local pushed = false
    if not state then return false, nil end
    nearbyCount = math.max(1, tonumber(state.nearbyCount) or 0)
    part = Wounds and Wounds.ChooseZombieAttackPart
        and Wounds.ChooseZombieAttackPart() or nil
    damageType = Wounds and Wounds.RollZombieAttackType
        and Wounds.RollZombieAttackType() or "scratch"
    chance, protection, fitness, mobilityChance =
        Defense.CalculateAvoidChance(
            record, npcBody, damageType, nearbyCount, part
        )
    roll = Internal.RandomUnit()
    avoided = roll < chance
    if avoided then
        pushRoll, pushed = Internal.ResolveNearMiss(
            record,
            npcBody,
            zombie,
            now,
            tonumber(Const.NPC_ZOMBIE_DEFENSE_PUSH_CHANCE) or 0.50
        )
    end
    storeLegacyResult(
        state, part, damageType, fitness, protection,
        mobilityChance, chance, roll, avoided, pushRoll, pushed, now
    )
    return avoided, {
        outcome = state.outcome,
        part = part,
        partId = state.partId,
        damageType = damageType,
        nearbyCount = nearbyCount,
        radius = state.radius,
        fitness = fitness,
        protection = protection,
        mobilityChance = mobilityChance,
        avoidChance = chance,
        roll = roll,
        pushed = pushed,
    }
end
