local T = require "tests/support/test"

local Registry = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitRegistry.lua")
local Effects = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitEffects.lua")
T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitDefinitions.lua")

PNC.Core = {
    IsAuthority = function() return true end,
}
PNC.Const = { MELEE_RANGE = 1.3 }
PNC.Skills = {
    GetLevel = function(_, skill)
        return skill == "Strength" and 5 or 4
    end,
}
PNC.CombatResolution = PNC.CombatResolution or {}
T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_MeleeOutcome.lua")

local ok, id = Registry.Register({
    id = "testmod:brawler",
    labelKey = "UI_Test_Trait_Brawler",
    descriptionKey = "UI_Test_Trait_Brawler_Description",
    effects = {
        personality = { aggression = 0.10, bravery = 0.05 },
        combat = {
            melee = {
                attackRateMultiplier = 1.20,
                windupTimeMultiplier = 0.80,
                hitChanceBias = -0.03,
                pressureAccuracyBias = -0.02,
            },
        },
    },
})
T.truthy(ok, "third-party melee trait registration")
T.equal(id, "testmod:brawler", "melee trait ID is canonical")

local record = {
    id = "melee_trait_npc",
    npcTraits = { [id] = true },
    runtime = {},
}
local modifiers = Effects.ResolveMeleeModifiers(record)
T.near(modifiers.attackRateMultiplier, 1.20, 0.0001,
    "melee trait increases attack rate")
T.near(modifiers.windupTimeMultiplier, 0.80, 0.0001,
    "melee trait shortens wind-up")
T.near(modifiers.hitChanceBias, -0.026, 0.0001,
    "melee trait compounds aggression with accuracy")
T.near(modifiers.pressureAccuracyBias, -0.014, 0.0001,
    "melee trait compounds bravery with pressure accuracy")
T.equal(Effects.ResolveMeleeModifiers(record), modifiers,
    "melee modifiers are cached")

local cooldown = PNC.CombatResolution.GetMeleeCooldown(
    record, 1200, modifiers, { actionDurationMs = 760 })
T.near(cooldown, 1000, 0.0001,
    "melee attack rate changes cooldown")
local hitDelay, duration = PNC.CombatResolution.GetMeleeTiming(
    320, 760, modifiers)
T.near(hitDelay, 256, 0.0001,
    "melee wind-up multiplier changes hit delay")
T.near(duration, 760, 0.0001,
    "faster melee wind-up preserves action duration")

local profile = PNC.CombatResolution.BuildMeleeStrikeProfile(record, {
    distSq = 0.25,
}, {
    modifiers = modifiers,
    skillID = "Axe",
    skillLevel = 4,
    strengthLevel = 5,
    pressureCount = 2,
})
T.truthy(profile.hitChance > 0 and profile.hitChance < 1,
    "melee profile produces a bounded hit chance")
local hit, reason = PNC.CombatResolution.ResolveMeleeStrike(record, {}, {
    profile = { hitChance = 0.95 },
    roll = 0.96,
})
T.falsy(hit, "melee accuracy can miss")
T.equal(reason, "melee_miss", "melee miss has an explicit reason")
hit, reason = PNC.CombatResolution.ResolveMeleeStrike(record, {}, {
    profile = { hitChance = 0.95 },
    roll = 0.10,
})
T.truthy(hit, "melee accuracy can hit")
T.equal(reason, "melee_hit", "melee hit has an explicit reason")

Registry.Set(record, {})
T.near(Effects.ResolveMeleeModifiers(record).attackRateMultiplier,
    1.0, 0.0001, "changing traits invalidates melee modifier cache")

local invalid, invalidReason = Registry.Register({
    id = "testmod:invalid_melee",
    labelKey = "UI_Test_Trait_InvalidMelee",
    effects = {
        combat = { melee = { hitChanceBias = "not-a-number" } },
    },
})
T.falsy(invalid, "invalid melee effect definitions are rejected")
T.contains(invalidReason, "invalid_combat_melee_hitChanceBias",
    "invalid melee registration explains the rejected field")

T.finish("pnc_melee_trait_resolution_smoke")
