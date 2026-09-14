local T = require "tests/support/test"

local Registry = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitRegistry.lua")
local Effects = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitEffects.lua")
T.load(
    "ProjectHoomans", "shared", "PNC/Core/Traits/PNC_NPCTraitDefinitions.lua")
local FatigueGate = T.load(
    "ProjectHoomans", "shared", "PNC/Core/Needs/PNC_WorkFatigueGate.lua")

local record = {
    npcTraits = {
        pnc_friendly = true,
        pnc_withdrawn = true,
        pnc_jealous = true,
        hasfriend = true,
    },
    dynamicTraits = { pnc_secondwind = true },
}

local collected = Registry.Collect(record)
T.truthy(collected.pnc_friendly, "friendly NPC trait is collected")
T.falsy(collected.pnc_withdrawn, "mutually exclusive NPC trait is resolved")
T.truthy(collected.pnc_jealous, "jealous NPC trait is collected")
T.falsy(collected.hasfriend, "player history trait is not an NPC trait")

local profile = Effects.ApplyPersonality({
    sociability = 0.50,
    forgiveness = 0.50,
    compassion = 0.50,
    aggression = 0.50,
}, record)
T.near(profile.sociability, 0.62, 0.0001,
    "friendly modifies sociability")
T.near(profile.forgiveness, 0.52, 0.0001,
    "friendly and jealous effects compound")
T.near(profile.compassion, 0.56, 0.0001,
    "friendly modifies compassion")

local fatigueMultiplier = Effects.GetNeedRateMultiplier(
    record, "fatigue", { fatigue = 0.80 }, "idle")
T.near(fatigueMultiplier, 0.70, 0.0001,
    "second wind modifies awake fatigue rate")
T.near(Effects.GetBehaviorModifier(record, "continueWorking"), 0.08,
    0.0001, "second wind exposes a behavior modifier")
local canContinue = FatigueGate.Check({
    dynamicTraits = { pnc_secondwind = true },
    fatigue = 0.95,
})
T.truthy(canContinue, "second wind changes work fatigue admission")

local stressMultiplier = Effects.GetConditionRateMultiplier(
    { dynamicTraits = { pnc_ironnerves = true } }, "stress", 1)
T.near(stressMultiplier, 0.75, 0.0001,
    "iron nerves modifies stress rate")

local sleepPolicy = Effects.ResolveSleepPolicy({
    npcTraits = { pnc_light_sleeper = true },
}, {
    actionable = 0.70,
    critical = 0.80,
    completion = 0.12,
    recoveryPerGameHour = 0.45,
})
T.near(sleepPolicy.actionable, 0.77, 0.0001,
    "light sleeper changes sleep trigger")
T.near(sleepPolicy.completion, 0.15, 0.0001,
    "light sleeper changes wake threshold")
T.near(sleepPolicy.recoveryPerGameHour, 0.60, 0.0001,
    "light sleeper changes sleep recovery")
T.near(Effects.GetNeedRateMultiplier({
    npcTraits = { pnc_light_sleeper = true },
}, "fatigue", { fatigue = 0.2 }, "idle"), 0.70, 0.0001,
    "canonical light-sleeper trait changes fatigue rate")

local firearmRecord = {
    npcTraits = { pnc_trigger_happy = true },
    dynamicTraits = {},
    npcTraitFingerprint = Registry.Fingerprint({ pnc_trigger_happy = true }),
    runtime = {},
}
local firearmModifiers = Effects.ResolveFirearmModifiers(firearmRecord)
T.near(firearmModifiers.fireRateMultiplier, 1.25, 0.0001,
    "trigger happy increases firearm rate")
T.near(firearmModifiers.aimTimeMultiplier, 0.82, 0.0001,
    "trigger happy settles aim sooner")
T.near(firearmModifiers.hitChanceBias, -0.08, 0.0001,
    "trigger happy reduces firearm hit chance")
T.near(firearmModifiers.pressureAccuracyBias, -0.023, 0.0001,
    "trigger happy reduces pressure accuracy")
T.equal(Effects.ResolveFirearmModifiers(firearmRecord), firearmModifiers,
    "firearm modifiers are cached for an unchanged trait set")
Registry.Set(firearmRecord, {})
T.near(Effects.ResolveFirearmModifiers(firearmRecord).fireRateMultiplier,
    1.0, 0.0001, "changing traits invalidates firearm modifier cache")

local ok, registered = Registry.Register({
    id = "testmod:kind",
    labelKey = "UI_Test_Trait_Kind",
    effects = { personality = { forgiveness = 0.05 } },
})
T.truthy(ok, "third-party NPC trait registration")
T.equal(registered, "testmod:kind", "registered ID is canonical")
T.truthy(Registry.GetDefinition("testmod:kind"),
    "registered NPC trait is discoverable")
T.falsy(Registry.NormalizeID("needslesssleep"),
    "unregistered player trait IDs do not enter the NPC registry")

local invalidCombat, invalidCombatReason = Registry.Register({
    id = "testmod:invalid_firearm",
    labelKey = "UI_Test_Trait_InvalidFirearm",
    effects = { combat = { firearm = { hitChanceBias = "not-a-number" } } },
})
T.falsy(invalidCombat, "invalid firearm effect definitions are rejected")
T.contains(invalidCombatReason, "invalid_combat_firearm_hitChanceBias",
    "invalid firearm registration explains the rejected field")

T.finish("pnc_npc_trait_effects_smoke")
