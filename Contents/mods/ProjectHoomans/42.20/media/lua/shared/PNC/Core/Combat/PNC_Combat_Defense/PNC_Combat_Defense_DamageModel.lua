local Defense = PNC.CombatDefense
local Internal = Defense.Internal
local Wounds = PNC.NPCWounds

local function rollDamageType()
    local part = Wounds and Wounds.ChooseZombieAttackPart
        and Wounds.ChooseZombieAttackPart() or nil
    local damageType = Wounds and Wounds.RollZombieAttackType
        and Wounds.RollZombieAttackType() or "scratch"
    return part, damageType
end

local function storeDamageModelResult(
    state, details, part, damageType,
    chance, roll, avoided, pushRoll, pushed, now
)
    state.damageModel = true
    state.damageType = damageType
    state.partId = part and part.id or nil
    state.fitness = details.fitness
    state.staminaRatio = details.staminaRatio
    state.safeStaminaRatio = details.safeStaminaRatio
    state.fatigueExposure = details.fatigueExposure
    state.crowdChance = details.crowdChance
    state.skillMitigation = details.skillMitigation
    state.baseChance = details.baseChance
    state.protection = 0
    state.mobilityChance = 1 - chance
    state.damageChance = chance
    state.avoidChance = 1 - chance
    state.roll = roll
    state.damageRoll = roll
    state.avoided = avoided
    state.pushRoll = pushRoll
    state.pushed = pushed
    state.lastResolvedAt = now
    state.outcome = avoided
        and (details.fatigueExposure <= 0 and "stamina_safe" or "avoided")
        or "hit"
end

local function damageModelPayload(
    state, details, part, damageType,
    nearbyCount, chance, roll, pushRoll, pushed
)
    return {
        outcome = state.outcome,
        damageModel = true,
        part = part,
        partId = state.partId,
        damageType = damageType,
        nearbyCount = nearbyCount,
        radius = state.radius,
        fitness = details.fitness,
        staminaRatio = details.staminaRatio,
        safeStaminaRatio = details.safeStaminaRatio,
        fatigueExposure = details.fatigueExposure,
        crowdChance = details.crowdChance,
        skillMitigation = details.skillMitigation,
        baseChance = details.baseChance,
        protection = 0,
        mobilityChance = 1 - chance,
        damageChance = chance,
        avoidChance = 1 - chance,
        roll = roll,
        damageRoll = roll,
        pushRoll = pushRoll,
        pushed = pushed,
    }
end

function Internal.ResolveDamageModelAttack(record, npcBody, zombie, now)
    local state = Defense.Refresh(record, npcBody, now)
    local nearbyCount
    local chance
    local details
    local roll
    local avoided
    local pushRoll
    local pushed = false
    local part
    local damageType
    if not state then return false, nil end
    nearbyCount = math.max(1, tonumber(state.nearbyCount) or 0)
    chance, details = Defense.CalculateDamageChance(record, nearbyCount)
    roll = Internal.RandomUnit()
    avoided = roll >= chance
    if avoided then
        pushRoll, pushed = Internal.ResolveNearMiss(
            record, npcBody, zombie, now
        )
    else
        -- Wound type is rolled only after stamina/crowd exposure succeeds.
        part, damageType = rollDamageType()
    end
    storeDamageModelResult(
        state, details, part, damageType,
        chance, roll, avoided, pushRoll, pushed, now
    )
    return avoided, damageModelPayload(
        state, details, part, damageType,
        nearbyCount, chance, roll, pushRoll, pushed
    )
end
