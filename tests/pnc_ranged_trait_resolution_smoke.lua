local T = require "tests/support/test"

PNC = {
    Core = {
        IsAuthority = function() return true end,
    },
    Const = {
        RANGED_RANGE = 8.5,
    },
    Skills = {
        GetLevel = function() return 0 end,
    },
    CombatResolution = {},
}

local Registry = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitRegistry.lua")
local Effects = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitEffects.lua")
T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitDefinitions.lua")
local Resolution = T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_RangedOutcome.lua")

local neutral = {
    npcTraits = {},
    dynamicTraits = {},
    runtime = { combatAim = { confidence = 0.80 } },
}
local triggerHappy = {
    npcTraits = { pnc_trigger_happy = true },
    dynamicTraits = {},
    runtime = { combatAim = { confidence = 0.80 } },
}
local target = { kind = "zombie", distSq = 9, x = 3, y = 0 }

local neutralModifiers = Effects.ResolveFirearmModifiers(neutral)
local triggerModifiers = Effects.ResolveFirearmModifiers(triggerHappy)
local neutralCooldown = Resolution.GetRangedCooldown(
    neutral, 1800, neutralModifiers)
local triggerCooldown = Resolution.GetRangedCooldown(
    triggerHappy, 1800, triggerModifiers)
T.near(neutralCooldown, 1800, 0.0001,
    "neutral NPC keeps the base ranged cooldown")
T.near(triggerCooldown, 1440, 0.0001,
    "trigger happy NPC gets a shorter ranged cooldown")

local neutralProfile = Resolution.BuildRangedShotProfile(neutral, target, {
    modifiers = neutralModifiers,
    aimConfidence = 0.80,
    pressureCount = 0,
})
local triggerProfile = Resolution.BuildRangedShotProfile(triggerHappy, target, {
    modifiers = triggerModifiers,
    aimConfidence = 0.80,
    pressureCount = 0,
})
T.truthy(neutralProfile.hitChance > triggerProfile.hitChance,
    "trigger happy lowers ranged hit chance")
local neutralHit = Resolution.ResolveRangedShot(neutral, target, {
    profile = neutralProfile,
    roll = 0,
})
T.truthy(neutralHit, "a low authoritative roll can hit")
local hit, reason, result = Resolution.ResolveRangedShot(neutral, target, {
    profile = neutralProfile,
    roll = 1,
})
T.falsy(hit, "a high authoritative roll can miss")
T.equal(reason, "ranged_miss", "misses have an explicit ranged outcome")
T.equal(result.roll, 1, "the shot stores its single accuracy roll")

PNC.Core.IsAuthority = function() return false end
local authorityHit, authorityReason = Resolution.ResolveRangedShot(
    neutral, target, { profile = neutralProfile, roll = 0 })
T.falsy(authorityHit, "clients cannot resolve ranged damage outcomes")
T.equal(authorityReason, "not_authority",
    "ranged accuracy is authority-gated")

T.finish("pnc_ranged_trait_resolution_smoke")
