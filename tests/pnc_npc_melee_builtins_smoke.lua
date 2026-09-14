local T = require "tests/support/test"

local Registry = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitRegistry.lua")
local Effects = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitEffects.lua")
T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitDefinitions.lua")

local expected = {
    "pnc_brawler",
    "pnc_disciplined_fighter",
    "pnc_reckless",
    "pnc_cautious_fighter",
    "pnc_berserker",
    "pnc_cowardly",
    "pnc_veteran",
    "pnc_nervous_fighter",
    "pnc_patient",
    "pnc_hasty",
    "pnc_scrapper",
    "pnc_peacemaker",
}

for _, id in ipairs(expected) do
    local definition = Registry.GetDefinition(id)
    T.truthy(definition, id .. " is registered")
    T.truthy(definition.labelKey, id .. " has a label key")
    T.truthy(definition.descriptionKey, id .. " has a description key")
    T.truthy(definition.iconPath, id .. " has a placeholder icon")
    T.truthy(definition.effects
        and definition.effects.combat
        and definition.effects.combat.melee,
        id .. " exposes melee effects")
    T.truthy(definition.generation
        and definition.generation.group
        and tonumber(definition.generation.weight) > 0,
        id .. " participates in registry-driven generation")
end

local selected = Registry.ResolveSet({
    pnc_brawler = true,
    pnc_disciplined_fighter = true,
})
T.truthy(selected.pnc_brawler ~= selected.pnc_disciplined_fighter,
    "brawler and disciplined fighter are mutually exclusive")

local brawler = Effects.ResolveMeleeModifiers({
    npcTraits = { pnc_brawler = true },
    runtime = {},
})
T.near(brawler.attackRateMultiplier, 1.12, 0.0001,
    "brawler uses the authored attack-rate multiplier")
T.near(brawler.windupTimeMultiplier, 0.94, 0.0001,
    "brawler uses the authored wind-up multiplier")
T.truthy(brawler.hitChanceBias > 0,
    "brawler compounds a positive melee hit bias")

T.finish("pnc_npc_melee_builtins_smoke")
