local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "assert") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy", 2) end
end

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = deepCopy(item) end
    return output
end

PNC = {
    Const = {
        DEFAULT_HP_MAX = 100,
        UNARMED_DAMAGE = 4,
        UNARMED_GROUND_DAMAGE = 7,
        UNARMED_COOLDOWN_MS = 900,
        PRESENCE_ABSTRACT = "abstract",
        ATTACK_TYPE_AUTO = "auto",
        ATTACK_TYPE_MELEE = "melee",
        ATTACK_TYPE_RANGED = "ranged",
        ATTACK_TYPE_NONE = "none",
    },
    Core = {
        DeepCopy = deepCopy,
        Now = function() return 100 end,
        GenerateID = function() return "generated_npc" end,
    },
    Identity = {},
    RelationshipTypes = {
        NewSocialState = function() return { schemaVersion = 3 } end,
    },
    FactionTypes = {
        NewAffiliation = function() return {} end,
    },
}

dofile(ROOT .. "shared/PNC/Core/Identity/PNC_Identity.lua")
dofile(ROOT .. "shared/PNC/Core/Needs/PNC_NeedsDefinitions.lua")
dofile(ROOT .. "shared/PNC/Core/Needs/PNC_ConditionStats.lua")
dofile(ROOT .. "shared/PNC/Core/Needs/PNC_PlayerNeedsModel.lua")
dofile(ROOT .. "shared/PNC/Core/Base/PNC_Types.lua")

local generatedA = PNC.Types.NewRecord({
    id = "npc_generated_a", identitySeed = 321, archetypeID = "General",
})
local generatedB = PNC.Types.NewRecord({
    id = "npc_generated_b", identitySeed = 321, archetypeID = "General",
})
equal(generatedA.vanillaTraitsAuthored, false,
    "generated traits are not marked authored")
equal(generatedA.vanillaTraitsGenerationVersion,
    PNC.PlayerNeedsModel.GENERATION_VERSION, "generation version")
equal(table.concat(PNC.PlayerNeedsModel.GetActiveTraitIDs(generatedA), "|"),
    table.concat(PNC.PlayerNeedsModel.GetActiveTraitIDs(generatedB), "|"),
    "same permanent identity seed produces the same traits")

local authored = PNC.Types.NewRecord({
    id = "npc_authored", identitySeed = 321,
    vanillaTraits = { "Base.HighThirst", "Overweight" },
})
equal(authored.vanillaTraitsAuthored, true, "authored trait source")
equal(authored.vanillaTraitsGenerationVersion, 0, "authored generation version")
equal(authored.vanillaTraits.highthirst, true, "authored high thirst")
equal(authored.vanillaTraits.overweight, true, "authored overweight")

local explicitlyTraitless = PNC.Types.NewRecord({
    id = "npc_traitless", identitySeed = 321, vanillaTraits = {},
})
equal(explicitlyTraitless.vanillaTraitsAuthored, true,
    "explicit empty traits are authoritative")
equal(#PNC.PlayerNeedsModel.GetActiveTraitIDs(explicitlyTraitless), 0,
    "explicit empty traits suppress generation")

local fingerprints = {}
for seed = 1, 200 do
    local traits = PNC.PlayerNeedsModel.GenerateTraits(seed, "General")
    local ids = PNC.PlayerNeedsModel.GetActiveTraitIDs(traits)
    fingerprints[table.concat(ids, "|")] = true
    truthy(not (traits.highthirst and traits.lowthirst),
        "thirst traits are mutually exclusive")
    truthy(not (traits.heartyappetite and traits.lighteater),
        "appetite traits are mutually exclusive")
    truthy(not (traits.needslesssleep and traits.needsmoresleep),
        "sleep traits are mutually exclusive")
    truthy(not (traits.veryunderweight and traits.heartyappetite),
        "vanilla very-underweight exclusion")
    truthy(not (traits.obese and traits.lighteater),
        "vanilla obese exclusion")
end
local variety = 0
for _ in pairs(fingerprints) do variety = variety + 1 end
truthy(variety > 10, "generated population has physiological variety")

local dynamicA = PNC.ConditionStats.GetActiveTraitIDs(generatedA)
local dynamicB = PNC.ConditionStats.GetActiveTraitIDs(generatedB)
equal(table.concat(dynamicA, "|"), table.concat(dynamicB, "|"),
    "custom traits are deterministic")
equal(generatedA.dynamicTraitsGenerationVersion,
    PNC.ConditionStats.TRAIT_GENERATION_VERSION,
    "custom trait generation version")

local iron = PNC.Types.NewRecord({
    id = "npc_iron", identitySeed = 9, vanillaTraits = {},
    dynamicTraits = { "PNC.IronNerves", "PNC.BusyHands" },
})
iron.needs = { hunger = 0.8, hydration = 0.2, fatigue = 0.2 }
local normalCondition = PNC.Types.NewRecord({
    id = "npc_condition_normal", identitySeed = 9, vanillaTraits = {},
    dynamicTraits = {},
})
normalCondition.needs = deepCopy(iron.needs)
local ironRates = PNC.ConditionStats.GetRates(iron, "fighting")
local normalRates = PNC.ConditionStats.GetRates(normalCondition, "fighting")
truthy(ironRates.stress < normalRates.stress,
    "Iron Nerves reduces stress gain")
truthy(ironRates.panic < normalRates.panic,
    "Iron Nerves reduces panic gain")
PNC.ConditionStats.Update(iron, 1, "fighting", 1)
truthy(iron.conditionStats.panic > 0, "fighting raises panic")
PNC.ConditionStats.Update(iron, 1, "idle", 2)
truthy(iron.conditionStats.boredom > 0, "idle time raises boredom")

local hardy = PNC.Types.NewRecord({
    id = "npc_hardy", identitySeed = 4, vanillaTraits = {},
    dynamicTraits = { "PNC.Hardy" },
})
local plain = PNC.Types.NewRecord({
    id = "npc_plain", identitySeed = 4, vanillaTraits = {},
    dynamicTraits = {},
})
local state = { hunger = 0, hydration = 0, fatigue = 0 }
truthy(PNC.PlayerNeedsModel.GetRates(hardy, state, "idle").hunger
    < PNC.PlayerNeedsModel.GetRates(plain, state, "idle").hunger,
    "Hardy Constitution changes primary need rates")

print("pnc_npc_vanilla_traits_smoke: ok")
