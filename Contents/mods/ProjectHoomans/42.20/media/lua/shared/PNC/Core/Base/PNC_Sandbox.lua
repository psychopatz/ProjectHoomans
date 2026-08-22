-- Central accessors for Project Hoomans sandbox rules.

PNC = PNC or {}
PNC.Sandbox = PNC.Sandbox or {}

local Settings = PNC.Sandbox
local Core = PNC.Core

local function projectVars()
    return SandboxVars and SandboxVars.ProjectHoomans or nil
end

function Settings.GetBoolean(key, fallback)
    local vars = projectVars()
    if vars and vars[key] ~= nil then
        return vars[key] == true
    end
    return fallback == true
end

function Settings.GetNumber(key, fallback, minimum, maximum)
    local vars = projectVars()
    local value = tonumber(vars and vars[key]) or tonumber(fallback) or 0
    if minimum ~= nil then value = math.max(tonumber(minimum) or value, value) end
    if maximum ~= nil then value = math.min(tonumber(maximum) or value, value) end
    return value
end

function Settings.NPCMeleeWeaponSpawnChance()
    return Settings.GetNumber("NPCMeleeWeaponSpawnChance", 70, 0, 100)
end

function Settings.NPCRangedWeaponSpawnChance()
    return Settings.GetNumber("NPCRangedWeaponSpawnChance", 20, 0, 100)
end

function Settings.NPCZombieWoundChance()
    return Settings.GetNumber("NPCZombieWoundChance", 45, 0, 100)
end

function Settings.NPCZombieBiteChance()
    return Settings.GetNumber("NPCZombieBiteChance", 20, 0, 100)
end

function Settings.NPCZombieLacerationChance()
    return Settings.GetNumber("NPCZombieLacerationChance", 30, 0, 100)
end

function Settings.NPCZombieDamageModelEnabled()
    return Settings.GetBoolean("NPCZombieDamageModel", true)
end

function Settings.NPCZombieDamageStaminaStartRatio()
    return Settings.GetNumber("NPCZombieDamageStaminaStartRatio", 0.30, 0, 1)
end

function Settings.NPCZombieDamageBaseChance()
    return Settings.GetNumber("NPCZombieDamageBaseChance", 0, 0, 100)
end

function Settings.NPCZombieDamageHitRadius()
    return Settings.GetNumber("NPCZombieDamageHitRadius", 2.2, 0.1, 6)
end

function Settings.NPCZombieDamageCrowdChancePerExtra()
    return Settings.GetNumber("NPCZombieDamageCrowdChancePerExtra", 5, 0, 100)
end

function Settings.NPCZombieDamageCrowdEscalation()
    return Settings.GetNumber("NPCZombieDamageCrowdEscalation", 2, 0, 100)
end

function Settings.NPCZombieDamageCrowdChanceCap()
    return Settings.GetNumber("NPCZombieDamageCrowdChanceCap", 100, 0, 100)
end

function Settings.NPCZombieDamageMinimumSkillMitigation()
    return Settings.GetNumber("NPCZombieDamageMinimumSkillMitigation", 15, 0, 100)
end

function Settings.NPCZombieDamageFitnessMitigationScale()
    return Settings.GetNumber("NPCZombieDamageFitnessMitigationScale", 45, 0, 100)
end

function Settings.NPCZombieDamageMaximumSkillMitigation()
    return Settings.GetNumber("NPCZombieDamageMaximumSkillMitigation", 60, 0, 100)
end

function Settings.NPCZombieClothingConditionExponent()
    return Settings.GetNumber("NPCZombieClothingConditionExponent", 1.15, 0.1, 3)
end

function Settings.NPCZombieClothingBlockMultiplier()
    return Settings.GetNumber("NPCZombieClothingBlockMultiplier", 1, 0, 2)
end

function Settings.NPCZombieClothingDowngradeLaceration()
    return Settings.GetNumber("NPCZombieClothingDowngradeLaceration", 25, 0, 100)
end

function Settings.NPCZombieClothingDowngradeScratch()
    return Settings.GetNumber("NPCZombieClothingDowngradeScratch", 60, 0, 100)
end

function Settings.NPCZombieClothingSafeDurabilityLoss()
    return Settings.GetNumber("NPCZombieClothingSafeDurabilityLoss", 1, 0, 100)
end

function Settings.NPCZombieClothingPenetratingDurabilityLoss()
    return Settings.GetNumber("NPCZombieClothingPenetratingDurabilityLoss", 2, 0, 100)
end

function Settings.NPCZombieInfectionChance()
    local vars = projectVars()
    if vars and vars.NPCZombieInfectionChance ~= nil then
        return Settings.GetNumber("NPCZombieInfectionChance", 100, 0, 100)
    end
    -- Compatibility for saves created while infection was a boolean rule.
    if vars and vars.NPCZombieInfection ~= nil then
        return vars.NPCZombieInfection == true and 100 or 0
    end
    return 100
end

function Settings.NPCZombieInfectionEnabled()
    return Settings.NPCZombieInfectionChance() > 0
end

function Settings.NPCInfectionMortalityHours()
    return Settings.GetNumber("NPCInfectionMortalityHours", 48, 1, 168)
end

function Settings.NPCReanimationSeconds()
    return Settings.GetNumber("NPCReanimationSeconds", 3, 1, 60)
end

function Settings.CompanionAmmoRealismEnabled()
    -- Preserve the original key so existing sandbox presets and saves keep
    -- their configured value.
    return Settings.GetBoolean("NPCAmmoConsumption", false)
end

function Settings.NPCSupplyTransactionLoggingEnabled()
    return Settings.GetBoolean("NPCSupplyTransactionLogging", false)
end

function Settings.ComponentDeconstructionRefundPercent()
    return Settings.GetNumber("ComponentDeconstructionRefundPercent", 50, 0, 100)
end

function Settings.ConstructionCancellationRefundMultiplier()
    return Settings.GetNumber("ConstructionCancellationRefundMultiplier", 1.0,
        0, 2)
end

function Settings.PlayerOwnedNPCNeedMortalityEnabled()
    return Settings.GetBoolean("PlayerOwnedNPCNeedMortality", false)
end

function Settings.MobileGroupAccidentChance(groupType)
    local defaults = { REFUGEE = 30, LOOTER = 10, TRADER = 1 }
    local keys = {
        REFUGEE = "RefugeeAccidentDeathChance",
        LOOTER = "LooterAccidentDeathChance",
        TRADER = "CaravanAccidentDeathChance",
    }
    groupType = string.upper(tostring(groupType or ""))
    local key = keys[groupType]
    if not key then return 0 end
    return Settings.GetNumber(key, defaults[groupType], 0, 100)
end

function Settings.ZombiesTargetDownedNPC()
    return Settings.GetBoolean("ZombiesTargetDownedNPC", false)
end

function Settings.CanZombieTargetRecord(record, now)
    local health = record and record.health or nil
    local protectionUntil = tonumber(health and health.reviveProtectionUntil) or 0
    if protectionUntil > 0 then
        now = tonumber(now) or Core.Now()
        if now < protectionUntil then
            return false
        end
    end
    return not health
        or health.state ~= "incapacitated"
        or Settings.ZombiesTargetDownedNPC()
end
