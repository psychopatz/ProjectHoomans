local Defense = PNC.CombatDefense
local Internal = Defense.Internal
local Skills = PNC.Skills

local function staminaRatio(record)
    local stamina = PNC.Stamina
    if stamina and stamina.GetRatio then
        return Internal.Clamp(stamina.GetRatio(record), 0, 1)
    end
    return 1
end

local function fatigueExposure(ratio, safeRatio)
    local t
    ratio = Internal.Clamp(ratio, 0, 1)
    safeRatio = Internal.Clamp(safeRatio, 0, 1)
    if safeRatio <= 0 then return 1 end
    if ratio >= safeRatio then return 0 end
    t = Internal.Clamp((safeRatio - ratio) / safeRatio, 0, 1)
    return t * t * (3 - (2 * t))
end

local function crowdChance(nearbyCount)
    local extra = math.max(0, nearbyCount - 1)
    local escalation = math.max(0, extra - 2)
    local chance = extra * Internal.SettingNumber(
        "NPCZombieDamageCrowdChancePerExtra", 5, 0, 100
    )
    chance = chance + (escalation * escalation
        * Internal.SettingNumber(
            "NPCZombieDamageCrowdEscalation", 2, 0, 100
        ))
    return math.min(
        chance,
        Internal.SettingNumber(
            "NPCZombieDamageCrowdChanceCap", 100, 0, 100
        )
    )
end

local function skillMitigation(fitness)
    local minimum = Internal.SettingNumber(
        "NPCZombieDamageMinimumSkillMitigation", 15, 0, 100
    ) / 100
    local scale = Internal.SettingNumber(
        "NPCZombieDamageFitnessMitigationScale", 45, 0, 100
    ) / 100
    local maximum = Internal.SettingNumber(
        "NPCZombieDamageMaximumSkillMitigation", 60, 0, 100
    ) / 100
    return Internal.Clamp(minimum + (fitness / 10) * scale, 0, maximum)
end

function Defense.CalculateDamageChance(record, nearbyCount)
    local fitness = Skills and Skills.GetLevel
        and Skills.GetLevel(record, "Fitness") or 0
    local stamina = staminaRatio(record)
    local safeRatio = Internal.SettingNumber(
        "NPCZombieDamageStaminaStartRatio", 0.30, 0, 1
    )
    local exposure = fatigueExposure(stamina, safeRatio)
    local crowd
    local base
    local mitigation
    local chance
    fitness = Internal.Clamp(fitness, 0, 10)
    nearbyCount = math.max(1, math.floor(tonumber(nearbyCount) or 1))
    crowd = crowdChance(nearbyCount)
    base = Internal.SettingNumber("NPCZombieDamageBaseChance", 0, 0, 100)
    mitigation = skillMitigation(fitness)
    chance = Internal.Clamp((base + crowd) / 100, 0, 1)
        * exposure * (1 - mitigation)
    return Internal.Clamp(chance, 0, 1), {
        fitness = fitness,
        staminaRatio = stamina,
        safeStaminaRatio = safeRatio,
        fatigueExposure = exposure,
        nearbyCount = nearbyCount,
        crowdChance = crowd,
        skillMitigation = mitigation,
        baseChance = base,
    }
end
