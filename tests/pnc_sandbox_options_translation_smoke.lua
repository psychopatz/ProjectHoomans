local T = require "tests/support/test"

local sandboxOptions = T.read("ProjectHoomans", "mod",
    "media/sandbox-options.txt")
local sandboxTranslations = T.read("ProjectHoomans", "common_mod",
    "media/lua/shared/Translate/EN/Sandbox.json")

PNC = { Core = { Now = function() return 0 end } }
SandboxVars = nil
T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Sandbox.lua")
local settings = PNC.Sandbox

local function escapePattern(value)
    return (value:gsub("([^%w])", "%%%1"))
end

local function translationValue(key)
    local pattern = '"' .. escapePattern(key)
        .. '"%s*:%s*"([^"]*)"'
    return sandboxTranslations:match(pattern)
end

local function assertTranslation(key, label)
    local value = translationValue(key)
    T.truthy(value, label .. " is missing")
    T.falsy(value == key, label .. " still exposes its raw key")
    return value
end

local knownOptions = {
    "ProjectHoomans.PlayerOwnedNPCNeedMortality",
    "ProjectHoomans.PlayerOwnedNPCNutritionMode",
}

local optionAccessors = {
    PlayerOwnedNPCNeedMortality = "PlayerOwnedNPCNeedMortalityEnabled",
    PlayerOwnedNPCNutritionMode = "PlayerOwnedNPCNutritionMode",
    NPCPopulation = "NPCPopulation",
    SettlementDensity = "SettlementDensity",
    RoamingGroupDensity = "RoamingGroupDensity",
    PopulationRegeneration = "PopulationRegeneration",
    SettlementRegeneration = "SettlementRegeneration",
    MultiplayerPopulationScaling = "MultiplayerPopulationScaling",
    PopulationGenerationDistance = "PopulationGenerationDistance",
    RefugeeAccidentDeathChance = "RefugeeAccidentDeathChance",
    LooterAccidentDeathChance = "LooterAccidentDeathChance",
    CaravanAccidentDeathChance = "CaravanAccidentDeathChance",
    NPCMeleeWeaponSpawnChance = "NPCMeleeWeaponSpawnChance",
    NPCRangedWeaponSpawnChance = "NPCRangedWeaponSpawnChance",
    ZombiesTargetDownedNPC = "ZombiesTargetDownedNPC",
    NPCZombieDamageModel = "NPCZombieDamageModelEnabled",
    NPCZombieDamageStaminaStartRatio = "NPCZombieDamageStaminaStartRatio",
    NPCZombieDamageBaseChance = "NPCZombieDamageBaseChance",
    NPCZombieDamageHitRadius = "NPCZombieDamageHitRadius",
    NPCZombieDamageCrowdChancePerExtra = "NPCZombieDamageCrowdChancePerExtra",
    NPCZombieDamageCrowdEscalation = "NPCZombieDamageCrowdEscalation",
    NPCZombieDamageCrowdChanceCap = "NPCZombieDamageCrowdChanceCap",
    NPCZombieDamageMinimumSkillMitigation = "NPCZombieDamageMinimumSkillMitigation",
    NPCZombieDamageFitnessMitigationScale = "NPCZombieDamageFitnessMitigationScale",
    NPCZombieDamageMaximumSkillMitigation = "NPCZombieDamageMaximumSkillMitigation",
    NPCZombieClothingConditionExponent = "NPCZombieClothingConditionExponent",
    NPCZombieClothingBlockMultiplier = "NPCZombieClothingBlockMultiplier",
    NPCZombieClothingDowngradeLaceration = "NPCZombieClothingDowngradeLaceration",
    NPCZombieClothingDowngradeScratch = "NPCZombieClothingDowngradeScratch",
    NPCZombieClothingSafeDurabilityLoss = "NPCZombieClothingSafeDurabilityLoss",
    NPCZombieClothingPenetratingDurabilityLoss = "NPCZombieClothingPenetratingDurabilityLoss",
    NPCZombieWoundChance = "NPCZombieWoundChance",
    NPCZombieBiteChance = "NPCZombieBiteChance",
    NPCZombieLacerationChance = "NPCZombieLacerationChance",
    NPCZombieInfectionChance = "NPCZombieInfectionChance",
    NPCInfectionMortalityHours = "NPCInfectionMortalityHours",
    NPCReanimationSeconds = "NPCReanimationSeconds",
    EnableWeaponDamage = "NPCWeaponDamageEnabled",
    NPCDamageDealtMultiplier = "NPCDamageDealtMultiplier",
    NPCPlayerWounds = "NPCPlayerWoundsEnabled",
    NPCAmmoConsumption = "NPCAmmoConsumptionEnabled",
    NPCWeaponConditionLoss = "NPCWeaponConditionLossEnabled",
    NPCSupplyTransactionLogging = "NPCSupplyTransactionLoggingEnabled",
    ComponentDeconstructionRefundPercent = "ComponentDeconstructionRefundPercent",
    ConstructionCancellationRefundMultiplier = "ConstructionCancellationRefundMultiplier",
    RadioDiscoveryEnabled = "RadioDiscoveryEnabled",
    RadioDiscoveryCooldownMinutes = "RadioDiscoveryCooldownHours",
    RadioDiscoverySignalChance = "RadioDiscoverySignalChance",
    RadioDiscoveryLineSpacingSeconds = "RadioDiscoveryLineSpacingSeconds",
    RadioAmbientEnabled = "RadioAmbientEnabled",
    RadioAmbientIntervalSeconds = "RadioAmbientIntervalSeconds",
    RadioAmbientChance = "RadioAmbientChance",
}

for i = 1, #knownOptions do
    T.contains(sandboxOptions, "option " .. knownOptions[i],
        knownOptions[i] .. " declaration")
end

local optionCount = 0
local declaredOptions = {}
for identifier, body in sandboxOptions:gmatch(
    "option%s+([%w_]+%.[%w_]+)%s*(%b{})"
) do
    optionCount = optionCount + 1
    local optionName = identifier:match("^[%w_]+%.([%w_]+)$")
    declaredOptions[optionName] = true

    local translation = body:match(
        "translation%s*=%s*([%w_]+%.[%w_]+)")
    T.equal(translation, identifier,
        identifier .. " translation declaration")

    local key = "Sandbox_" .. translation
    assertTranslation(key, key)
    assertTranslation(key .. "_tooltip", key .. " tooltip")

    local accessorName = optionAccessors[optionName]
    T.truthy(accessorName,
        key .. " is missing from the central accessor map")
    T.equal(type(settings[accessorName]), "function",
        key .. " central accessor")
    T.truthy(settings[accessorName]() ~= nil,
        key .. " central accessor returns nil")

    local optionType = body:match("type%s*=%s*([%w_]+)")
    local numValues = tonumber(body:match("numValues%s*=%s*(%d+)"))
    if optionType == "enum" then
        T.truthy(numValues and numValues > 0,
            key .. " enum value count")
        for valueIndex = 1, numValues do
            assertTranslation(key .. "_option" .. valueIndex,
                key .. " option" .. valueIndex)
        end
    end
end

T.truthy(optionCount > 0, "sandbox option declarations were not found")
for optionName, _ in pairs(optionAccessors) do
    T.truthy(declaredOptions[optionName],
        optionName .. " accessor map entry has no declared option")
end

T.equal(settings.PlayerOwnedNPCNeedMortalityEnabled(), true,
    "need mortality default")
T.equal(settings.PlayerOwnedNPCNutritionMode(), "simple",
    "nutrition mode default")
T.equal(settings.NPCPopulation(), 4, "population default")
T.equal(settings.RefugeeAccidentDeathChance(), 30,
    "refugee accident default")
T.equal(settings.LooterAccidentDeathChance(), 10,
    "looter accident default")
T.equal(settings.CaravanAccidentDeathChance(), 1,
    "caravan accident default")
T.equal(settings.RadioDiscoveryEnabled(), true,
    "radio discovery default")
T.equal(settings.RadioDiscoveryCooldownHours(), 0.5,
    "radio discovery cooldown default")
T.equal(settings.RadioDiscoverySignalChance(), 100,
    "radio signal chance default")
T.equal(settings.RadioDiscoveryLineSpacingSeconds(), 2,
    "radio line spacing default")
T.equal(settings.RadioAmbientEnabled(), true,
    "ambient radio default")
T.equal(settings.RadioAmbientIntervalSeconds(), 90,
    "ambient radio interval default")
T.equal(settings.RadioAmbientChance(), 65,
    "ambient radio chance default")
T.equal(settings.NPCWeaponDamageEnabled(), true,
    "weapon damage default")
T.near(settings.NPCDamageDealtMultiplier(), 1, 0.000001,
    "weapon damage multiplier default")
T.equal(settings.NPCPlayerWoundsEnabled(), true,
    "player wounds default")
T.equal(settings.NPCAmmoConsumptionEnabled(), false,
    "ammo consumption default")
T.equal(settings.NPCWeaponConditionLossEnabled(), false,
    "weapon condition default")

SandboxVars = { ProjectHoomans = {
    PlayerOwnedNPCNeedMortality = false,
    PlayerOwnedNPCNutritionMode = 2,
    NPCPopulation = 6,
    RefugeeAccidentDeathChance = 0,
    RadioDiscoveryCooldownMinutes = 90,
    EnableWeaponDamage = false,
    NPCDamageDealtMultiplier = 3.5,
    NPCAmmoConsumption = true,
} }
T.equal(settings.PlayerOwnedNPCNeedMortalityEnabled(), false,
    "need mortality override")
T.equal(settings.PlayerOwnedNPCNutritionMode(), "realism",
    "nutrition mode override")
T.equal(settings.NPCPopulation(), 6, "population override")
T.equal(settings.RefugeeAccidentDeathChance(), 0,
    "refugee accident override")
T.equal(settings.RadioDiscoveryCooldownHours(), 1.5,
    "radio cooldown override")
T.equal(settings.NPCWeaponDamageEnabled(), false,
    "weapon damage override")
T.near(settings.NPCDamageDealtMultiplier(), 3.5, 0.000001,
    "weapon damage multiplier override")
T.equal(settings.NPCAmmoConsumptionEnabled(), true,
    "ammo consumption override")
T.finish("pnc_sandbox_options_translation_smoke")
