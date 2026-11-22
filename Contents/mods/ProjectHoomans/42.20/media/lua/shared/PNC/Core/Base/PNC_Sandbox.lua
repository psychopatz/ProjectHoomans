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

local function populationOption(key)
    return Settings.GetNumber(key, 4, 1, 6)
end

function Settings.NPCPopulation()
    return populationOption("NPCPopulation")
end

function Settings.SettlementDensity()
    return populationOption("SettlementDensity")
end

function Settings.RoamingGroupDensity()
    return populationOption("RoamingGroupDensity")
end

function Settings.PopulationRegeneration()
    return populationOption("PopulationRegeneration")
end

function Settings.SettlementRegeneration()
    return populationOption("SettlementRegeneration")
end

function Settings.MultiplayerPopulationScaling()
    return populationOption("MultiplayerPopulationScaling")
end

function Settings.PopulationGenerationDistance()
    return populationOption("PopulationGenerationDistance")
end

function Settings.NPCMeleeWeaponSpawnChance()
    return Settings.GetNumber("NPCMeleeWeaponSpawnChance", 70, 0, 100)
end

function Settings.NPCRangedWeaponSpawnChance()
    return Settings.GetNumber("NPCRangedWeaponSpawnChance", 20, 0, 100)
end

function Settings.CompanionAmmoRealismEnabled()
    -- Preserve the original key so existing sandbox presets and saves keep
    -- their configured value.
    return Settings.GetBoolean("NPCAmmoConsumption", false)
end

function Settings.NPCWeaponDamageEnabled()
    return Settings.GetBoolean("EnableWeaponDamage", true)
end

function Settings.NPCDamageDealtMultiplier()
    return Settings.GetNumber("NPCDamageDealtMultiplier", 1, 0, 10)
end

function Settings.NPCPlayerWoundsEnabled()
    return Settings.GetBoolean("NPCPlayerWounds", true)
end

function Settings.NPCAmmoConsumptionEnabled()
    return Settings.GetBoolean("NPCAmmoConsumption", false)
end

function Settings.NPCWeaponConditionLossEnabled()
    return Settings.GetBoolean("NPCWeaponConditionLoss", false)
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

function Settings.RadioDiscoveryEnabled()
    return Settings.GetBoolean("RadioDiscoveryEnabled", true)
end

function Settings.RadioDiscoveryCooldownHours()
    return Settings.GetNumber("RadioDiscoveryCooldownMinutes", 30, 1, 1440)
        / 60
end

function Settings.RadioDiscoverySignalChance()
    return Settings.GetNumber("RadioDiscoverySignalChance", 100, 0, 100)
end

function Settings.RadioDiscoveryLineSpacingSeconds()
    return Settings.GetNumber("RadioDiscoveryLineSpacingSeconds", 2, 0, 10)
end

function Settings.RadioAmbientEnabled()
    return Settings.GetBoolean("RadioAmbientEnabled", true)
end

function Settings.RadioAmbientIntervalSeconds()
    return Settings.GetNumber("RadioAmbientIntervalSeconds", 90, 30, 600)
end

function Settings.RadioAmbientChance()
    return Settings.GetNumber("RadioAmbientChance", 65, 0, 100)
end

function Settings.PlayerOwnedNPCNeedMortalityEnabled()
    return Settings.GetBoolean("PlayerOwnedNPCNeedMortality", true)
end

-- One world-wide mode keeps the hot path branch predictable and avoids
-- storing a mode flag on each NPC.  1 is the cheap hunger/thirst model; 2
-- enables the player-shaped calorie, macro, and weight simulation.
function Settings.PlayerOwnedNPCNutritionMode()
    local vars = projectVars()
    local mode = math.floor(tonumber(vars and vars.PlayerOwnedNPCNutritionMode) or 1)
    return mode == 2 and "realism" or "simple"
end

function Settings.PlayerOwnedNPCNutritionRealismEnabled()
    return Settings.PlayerOwnedNPCNutritionMode() == "realism"
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

function Settings.RefugeeAccidentDeathChance()
    return Settings.GetNumber("RefugeeAccidentDeathChance", 30, 0, 100)
end

function Settings.LooterAccidentDeathChance()
    return Settings.GetNumber("LooterAccidentDeathChance", 10, 0, 100)
end

function Settings.CaravanAccidentDeathChance()
    return Settings.GetNumber("CaravanAccidentDeathChance", 1, 0, 100)
end

function Settings.MobileSettlementAIJoinChance()
    return Settings.GetNumber("MobileSettlementAIJoinChance", 35, 0, 100)
end

function Settings.ZombiesTargetDownedNPC()
    return Settings.GetBoolean("ZombiesTargetDownedNPC", false)
end

function Settings.CanZombieTargetRecord(record, now)
    local health = record and record.health or nil
    local protectionUntil = tonumber(health and health.reviveProtectionUntil) or 0
    local livePresence = PNC.Const and PNC.Const.PRESENCE_LIVE or nil
    -- The downed-target preference only applies to living records.  A corpse
    -- can retain an incapacitated health snapshot while its registry state has
    -- already transitioned to dead/corpse, so that snapshot must never reopen
    -- the zombie target gate.
    if not record
        or record.alive == false
        or health and health.state == "dead"
        or livePresence
            and record.presenceState ~= nil
            and record.presenceState ~= livePresence
    then
        return false
    end
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

require "PNC/Core/Base/PNC_Sandbox_Health"
