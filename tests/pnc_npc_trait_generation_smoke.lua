local T = require "tests/support/test"

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
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
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

T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Needs/PNC_NeedsDefinitions.lua")
local Registry = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitRegistry.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitEffects.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitDefinitions.lua")
local Stats = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Needs/PNC_ConditionStats.lua")
T.load(
    "ProjectHoomans", "shared", "PNC/Core/Needs/PNC_PlayerNeedsModel.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitContext.lua")
local Types = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Base/PNC_Types.lua")

local function findGroup(groups, id)
    for index = 1, #groups do
        if groups[index].id == id then return groups[index] end
    end
    return nil
end

local groups = Registry.GetGenerationGroups()
local combatStyle = findGroup(groups, "combat_style")
local combatTemperament = findGroup(groups, "combat_temperament")
T.truthy(combatStyle, "combat style generation group is registered")
T.truthy(combatTemperament, "combat temperament generation group is registered")
T.equal(combatStyle.noneWeight, 55, "combat style none weight")
T.equal(combatTemperament.noneWeight, 65,
    "combat temperament none weight")
T.equal(Stats.TRAIT_GENERATION_VERSION, 2,
    "registry-driven generation version")

local styleTraits = {
    pnc_brawler = true,
    pnc_disciplined_fighter = true,
    pnc_cautious_fighter = true,
    pnc_patient = true,
    pnc_hasty = true,
    pnc_scrapper = true,
    pnc_peacemaker = true,
}
local temperamentTraits = {
    pnc_reckless = true,
    pnc_berserker = true,
    pnc_cowardly = true,
    pnc_veteran = true,
    pnc_nervous_fighter = true,
}
local sawStyle = false
local sawTemperament = false
local sawCompound = false
local firstFingerprint
for seed = 1, 2000 do
    local generated = Stats.GenerateTraits(seed, "General")
    local hasStyle = false
    local hasTemperament = false
    for id, _ in pairs(generated) do
        if styleTraits[id] then hasStyle = true end
        if temperamentTraits[id] then hasTemperament = true end
    end
    if hasStyle then sawStyle = true end
    if hasTemperament then sawTemperament = true end
    if hasStyle and hasTemperament then sawCompound = true end
    if seed == 137 then
        firstFingerprint = Registry.Fingerprint(generated)
    end
end
T.truthy(sawStyle, "generated NPCs receive a combat style")
T.truthy(sawTemperament, "generated NPCs receive a combat temperament")
T.truthy(sawCompound,
    "independent combat groups can compound on one generated NPC")
T.equal(Registry.Fingerprint(Stats.GenerateTraits(137, "General")),
    firstFingerprint, "generation is deterministic for the same identity")

local ok, reason = Registry.Register({
    id = "testmod:unknown_generation",
    labelKey = "UI_Test_Trait_UnknownGeneration",
    generation = { group = "testmod:missing", weight = 1 },
    effects = {},
})
T.falsy(ok, "unknown generation groups are rejected")
T.contains(reason, "unknown_generation_group",
    "unknown generation group rejection reason")

ok, reason = Registry.Register({
    id = "testmod:negative_generation",
    labelKey = "UI_Test_Trait_NegativeGeneration",
    generation = { group = "combat_style", weight = -1 },
    effects = {},
})
T.falsy(ok, "negative generation weights are rejected")
T.contains(reason, "invalid_generation_weight",
    "invalid generation weight rejection reason")

ok, reason = Registry.Register({
    id = "testmod:generated_style",
    labelKey = "UI_Test_Trait_GeneratedStyle",
    generation = { group = "combat_style", weight = 1 },
    effects = { personality = { sociability = 0.01 } },
})
T.truthy(ok, "a mod trait can join a built-in generation group")
local sawModTrait = false
for seed = 1, 2000 do
    if Stats.GenerateTraits(seed, "General")["testmod:generated_style"] then
        sawModTrait = true
        break
    end
end
T.truthy(sawModTrait,
    "a registered mod trait is available to new NPC generation")

ok, reason = Registry.RegisterGenerationGroup({
    id = "testmod:occupation_style",
    noneWeight = 99,
    priority = 200,
})
T.truthy(ok, "mods can register a generation group")
ok, reason = Registry.Register({
    id = "testmod:occupation_trait",
    labelKey = "UI_Test_Trait_Occupation",
    generation = { group = "testmod:occupation_style", weight = 1 },
    effects = { behavior = { continueWorking = 0.10 } },
})
T.truthy(ok, "a trait can use a mod generation group")

local spawned = Types.NewRecord({
    id = "npc_generated_from_registry",
    identitySeed = 137,
    archetypeID = "General",
})
T.falsy(spawned.dynamicTraitsAuthored,
    "new NPCs use generated traits unless explicitly authored")
T.equal(spawned.dynamicTraitsGenerationVersion,
    Stats.TRAIT_GENERATION_VERSION, "new NPC stores the current generation version")
T.equal(Registry.Fingerprint(spawned.dynamicTraits),
    Registry.Fingerprint(Stats.GenerateTraits(
        spawned.identitySeed, spawned.archetypeID)),
    "new NPCs receive registry-driven generated traits")

local authored = {
    dynamicTraits = { pnc_brawler = true },
    dynamicTraitsAuthored = true,
    dynamicTraitsGenerationVersion = 0,
}
local authoredBefore = Registry.Fingerprint(authored.dynamicTraits)
local _, authoredChanged = Stats.EnsureTraits(authored)
T.falsy(authoredChanged, "authored dynamic traits are not regenerated")
T.equal(Registry.Fingerprint(authored.dynamicTraits), authoredBefore,
    "authored dynamic traits remain unchanged")

T.finish("pnc_npc_trait_generation_smoke")
