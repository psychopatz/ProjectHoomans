-- Built-in NPC traits. These are deliberately separate from player traits;
-- the same display concept may have different simulation effects for an NPC.

PNC = PNC or {}
local Traits = PNC.NPCTraits
-- Temporary shared icon until dedicated NPC combat trait art is authored.
local PLACEHOLDER_ICON = "media/ui/Traits/trait_pnc_friendly.png"

local function register(definition)
    local ok, reason = Traits.Register(definition)
    if not ok and PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("NPC trait registration failed id="
            .. tostring(definition and definition.id or "")
            .. " reason=" .. tostring(reason))
    end
end

register({
    id = "pnc_friendly",
    labelKey = "UI_PNC_Trait_Friendly",
    descriptionKey = "UI_PNC_Trait_Friendly_Description",
    iconPath = "media/ui/Traits/trait_pnc_friendly.png",
    source = "behavior",
    priority = 10,
    excludes = { "pnc_withdrawn" },
    effects = {
        personality = { sociability = 0.12, forgiveness = 0.10,
            compassion = 0.06 },
        categoryBiases = { socialStyle = { friendly = 1.0 } },
        behavior = { socialInteraction = 0.20 },
    },
})

register({
    id = "pnc_withdrawn",
    labelKey = "UI_PNC_Trait_Withdrawn",
    descriptionKey = "UI_PNC_Trait_Withdrawn_Description",
    iconPath = "media/ui/Traits/trait_pnc_withdrawn.png",
    source = "behavior",
    priority = 10,
    excludes = { "pnc_friendly" },
    effects = {
        personality = { sociability = -0.12, forgiveness = -0.03 },
        categoryBiases = { socialStyle = { withdrawn = 1.0 } },
        behavior = { socialInteraction = -0.20 },
    },
})

register({
    id = "pnc_jealous",
    labelKey = "UI_PNC_Trait_Jealous",
    descriptionKey = "UI_PNC_Trait_Jealous_Description",
    iconPath = "media/ui/Traits/trait_pnc_jealous.png",
    source = "behavior",
    excludes = { "pnc_unpossessive" },
    effects = {
        personality = { forgiveness = -0.08, aggression = 0.03 },
        categoryBiases = { jealousyStyle = { jealous = 1.0 } },
        behavior = { socialConflict = 0.08 },
    },
})

register({
    id = "pnc_unpossessive",
    labelKey = "UI_PNC_Trait_Unpossessive",
    descriptionKey = "UI_PNC_Trait_Unpossessive_Description",
    iconPath = "media/ui/Traits/trait_pnc_unpossessive.png",
    source = "behavior",
    excludes = { "pnc_jealous" },
    effects = {
        personality = { forgiveness = 0.08, aggression = -0.03 },
        categoryBiases = { jealousyStyle = { unpossessive = 1.0 } },
        behavior = { socialConflict = -0.08 },
    },
})

register({
    id = "pnc_flirty",
    labelKey = "UI_PNC_Trait_Flirty",
    descriptionKey = "UI_PNC_Trait_Flirty_Description",
    iconPath = "media/ui/Traits/trait_pnc_flirty.png",
    source = "preference",
    excludes = { "pnc_reserved" },
    effects = {
        personality = { sociability = 0.04 },
        categoryBiases = { romanceStyle = { flirty = 1.0 } },
        behavior = { socialInteraction = 0.08 },
    },
})

register({
    id = "pnc_reserved",
    labelKey = "UI_PNC_Trait_Reserved",
    descriptionKey = "UI_PNC_Trait_Reserved_Description",
    iconPath = "media/ui/Traits/trait_pnc_reserved.png",
    source = "behavior",
    excludes = { "pnc_flirty" },
    effects = {
        personality = { sociability = -0.04 },
        categoryBiases = { romanceStyle = { reserved = 1.0 } },
        behavior = { socialInteraction = -0.08 },
    },
})

register({
    id = "pnc_ironnerves",
    labelKey = "UI_PNC_Trait_IronNerves",
    descriptionKey = "UI_PNC_Trait_IronNerves_Description",
    iconPath = "media/ui/Traits/trait_pnc_ironnerves.png",
    source = "temperament",
    generation = { group = "nerves", weight = 18 },
    excludes = { "pnc_frayednerves" },
    effects = {
        personality = { bravery = 0.10, aggression = -0.03 },
        conditions = {
            stress = { positiveMultiplier = 0.75,
                negativeMultiplier = 1.20 },
            panic = { positiveMultiplier = 0.50,
                negativeMultiplier = 1.50 },
        },
    },
})

register({
    id = "pnc_frayednerves",
    labelKey = "UI_PNC_Trait_FrayedNerves",
    descriptionKey = "UI_PNC_Trait_FrayedNerves_Description",
    iconPath = "media/ui/Traits/trait_pnc_frayednerves.png",
    source = "temperament",
    generation = { group = "nerves", weight = 14 },
    excludes = { "pnc_ironnerves" },
    effects = {
        personality = { bravery = -0.08, aggression = 0.08,
            forgiveness = -0.04 },
        conditions = {
            stress = { positiveMultiplier = 1.25,
                negativeMultiplier = 0.75 },
            panic = { positiveMultiplier = 1.50,
                negativeMultiplier = 0.70 },
        },
    },
})

register({
    id = "pnc_busyhands",
    labelKey = "UI_PNC_Trait_BusyHands",
    descriptionKey = "UI_PNC_Trait_BusyHands_Description",
    iconPath = "media/ui/Traits/trait_pnc_busyhands.png",
    source = "behavior",
    generation = { group = "tempo", weight = 20 },
    excludes = { "pnc_restlesssoul" },
    effects = {
        behavior = { work = 0.08, recreation = -0.05 },
        conditions = { boredom = { positiveMultiplier = 0.60,
            negativeMultiplier = 1.20 } },
    },
})

register({
    id = "pnc_restlesssoul",
    labelKey = "UI_PNC_Trait_RestlessSoul",
    descriptionKey = "UI_PNC_Trait_RestlessSoul_Description",
    iconPath = "media/ui/Traits/trait_pnc_restlesssoul.png",
    source = "behavior",
    generation = { group = "tempo", weight = 15 },
    excludes = { "pnc_busyhands" },
    effects = {
        behavior = { work = -0.03, recreation = 0.10 },
        conditions = { boredom = { positiveMultiplier = 1.50,
            negativeMultiplier = 1.25 } },
    },
})

register({
    id = "pnc_hardy",
    labelKey = "UI_PNC_Trait_Hardy",
    descriptionKey = "UI_PNC_Trait_Hardy_Description",
    iconPath = "media/ui/Traits/trait_pnc_hardy.png",
    source = "physiology",
    generation = { group = "constitution", weight = 18 },
    excludes = { "pnc_delicate" },
    effects = {
        needs = {
            hunger = { awakeMultiplier = 0.90,
                sleepingMultiplier = 0.90 },
            thirst = { awakeMultiplier = 0.90,
                sleepingMultiplier = 0.90 },
        },
        personality = { bravery = 0.04 },
    },
})

register({
    id = "pnc_delicate",
    labelKey = "UI_PNC_Trait_Delicate",
    descriptionKey = "UI_PNC_Trait_Delicate_Description",
    iconPath = "media/ui/Traits/trait_pnc_delicate.png",
    source = "physiology",
    generation = { group = "constitution", weight = 14 },
    excludes = { "pnc_hardy" },
    effects = {
        needs = {
            hunger = { awakeMultiplier = 1.10,
                sleepingMultiplier = 1.10 },
            thirst = { awakeMultiplier = 1.10,
                sleepingMultiplier = 1.10 },
        },
        personality = { bravery = -0.04 },
    },
})

register({
    id = "pnc_secondwind",
    labelKey = "UI_PNC_Trait_SecondWind",
    descriptionKey = "UI_PNC_Trait_SecondWind_Description",
    iconPath = "media/ui/Traits/trait_pnc_secondwind.png",
    source = "physiology",
    generation = { group = "fatigue", weight = 16 },
    effects = {
        needs = {
            fatigue = { awakeMultiplier = 0.70,
                threshold = 0.70 },
        },
        personality = { bravery = 0.04 },
        behavior = { continueWorking = 0.08 },
    },
})

register({
    id = "pnc_light_sleeper",
    labelKey = "UI_PNC_Trait_LightSleeper",
    descriptionKey = "UI_PNC_Trait_LightSleeper_Description",
    iconPath = "media/ui/Traits/trait_pnc_lightsleeper.png",
    source = "physiology",
    excludes = { "pnc_heavysleeper" },
    effects = {
        needs = {
            fatigue = { awakeMultiplier = 0.70,
                sleepingMultiplier = 1.333333 },
            sleepPolicy = {
                actionThresholdMultiplier = 1.10,
                wakeThresholdMultiplier = 1.25,
                recoveryMultiplier = 1.333333,
            },
        },
        behavior = { sleep = -0.10, nightActivity = 0.10 },
    },
})

register({
    id = "pnc_heavysleeper",
    labelKey = "UI_PNC_Trait_HeavySleeper",
    descriptionKey = "UI_PNC_Trait_HeavySleeper_Description",
    iconPath = "media/ui/Traits/trait_pnc_heavysleeper.png",
    source = "physiology",
    generation = { group = "fatigue", weight = 12 },
    excludes = { "pnc_light_sleeper" },
    effects = {
        needs = {
            fatigue = { awakeMultiplier = 1.10,
                sleepingMultiplier = 0.847457 },
            sleepPolicy = {
                actionThresholdMultiplier = 0.95,
                wakeThresholdMultiplier = 0.75,
                recoveryMultiplier = 0.80,
            },
        },
        behavior = { sleep = 0.10, nightActivity = -0.10 },
    },
})

register({
    id = "pnc_trigger_happy",
    labelKey = "UI_PNC_Trait_TriggerHappy",
    descriptionKey = "UI_PNC_Trait_TriggerHappy_Description",
    iconPath = "media/ui/Traits/trait_pnc_trigger_happy.png",
    source = "combat",
    effects = {
        personality = { aggression = 0.06, bravery = 0.02 },
        combat = {
            firearm = {
                fireRateMultiplier = 1.25,
                aimTimeMultiplier = 0.82,
                hitChanceBias = -0.08,
                pressureAccuracyBias = -0.025,
            },
        },
    },
})

register({
    id = "pnc_brawler",
    labelKey = "UI_PNC_Trait_Brawler",
    descriptionKey = "UI_PNC_Trait_Brawler_Description",
    iconPath = PLACEHOLDER_ICON,
    source = "combat",
    generation = { group = "combat_style", weight = 8 },
    excludes = { "pnc_disciplined_fighter" },
    effects = {
        personality = { aggression = 0.06, bravery = 0.03 },
        combat = { melee = {
            attackRateMultiplier = 1.12, windupTimeMultiplier = 0.94,
            hitChanceBias = 0.02, pressureAccuracyBias = -0.01,
        } },
    },
})

register({
    id = "pnc_disciplined_fighter",
    labelKey = "UI_PNC_Trait_DisciplinedFighter",
    descriptionKey = "UI_PNC_Trait_DisciplinedFighter_Description",
    iconPath = PLACEHOLDER_ICON,
    source = "combat",
    generation = { group = "combat_style", weight = 7 },
    excludes = { "pnc_brawler" },
    effects = {
        personality = { bravery = 0.06, aggression = -0.02 },
        combat = { melee = {
            attackRateMultiplier = 0.94, windupTimeMultiplier = 1.04,
            hitChanceBias = 0.07, pressureAccuracyBias = 0.05,
        } },
    },
})

register({
    id = "pnc_reckless",
    labelKey = "UI_PNC_Trait_Reckless",
    descriptionKey = "UI_PNC_Trait_Reckless_Description",
    iconPath = PLACEHOLDER_ICON,
    source = "combat",
    generation = { group = "combat_temperament", weight = 8 },
    excludes = { "pnc_cautious_fighter" },
    effects = {
        personality = { aggression = 0.12, bravery = 0.05 },
        combat = { melee = {
            attackRateMultiplier = 1.20, windupTimeMultiplier = 0.84,
            hitChanceBias = -0.06, pressureAccuracyBias = -0.05,
        } },
    },
})

register({
    id = "pnc_cautious_fighter",
    labelKey = "UI_PNC_Trait_CautiousFighter",
    descriptionKey = "UI_PNC_Trait_CautiousFighter_Description",
    iconPath = PLACEHOLDER_ICON,
    source = "combat",
    generation = { group = "combat_style", weight = 6 },
    excludes = { "pnc_reckless" },
    effects = {
        personality = { aggression = -0.05, bravery = 0.02 },
        combat = { melee = {
            attackRateMultiplier = 0.88, windupTimeMultiplier = 1.12,
            hitChanceBias = 0.05, pressureAccuracyBias = 0.04,
        } },
    },
})

register({
    id = "pnc_berserker",
    labelKey = "UI_PNC_Trait_Berserker",
    descriptionKey = "UI_PNC_Trait_Berserker_Description",
    iconPath = PLACEHOLDER_ICON,
    source = "combat",
    generation = { group = "combat_temperament", weight = 5 },
    excludes = { "pnc_cowardly" },
    effects = {
        personality = { aggression = 0.15, bravery = 0.08 },
        combat = { melee = {
            attackRateMultiplier = 1.16, windupTimeMultiplier = 0.88,
            hitChanceBias = 0.01, pressureAccuracyBias = -0.04,
        } },
    },
})

register({
    id = "pnc_cowardly",
    labelKey = "UI_PNC_Trait_Cowardly",
    descriptionKey = "UI_PNC_Trait_Cowardly_Description",
    iconPath = PLACEHOLDER_ICON,
    source = "combat",
    generation = { group = "combat_temperament", weight = 7 },
    excludes = { "pnc_berserker" },
    effects = {
        personality = { aggression = -0.10, bravery = -0.12 },
        combat = { melee = {
            attackRateMultiplier = 0.84, windupTimeMultiplier = 1.18,
            hitChanceBias = -0.03, pressureAccuracyBias = -0.08,
        } },
    },
})

register({
    id = "pnc_veteran",
    labelKey = "UI_PNC_Trait_Veteran",
    descriptionKey = "UI_PNC_Trait_Veteran_Description",
    iconPath = PLACEHOLDER_ICON,
    source = "combat",
    generation = { group = "combat_temperament", weight = 7 },
    excludes = { "pnc_nervous_fighter" },
    effects = {
        personality = { bravery = 0.10, aggression = 0.02 },
        combat = { melee = {
            attackRateMultiplier = 0.98, windupTimeMultiplier = 0.96,
            hitChanceBias = 0.08, pressureAccuracyBias = 0.08,
        } },
    },
})

register({
    id = "pnc_nervous_fighter",
    labelKey = "UI_PNC_Trait_NervousFighter",
    descriptionKey = "UI_PNC_Trait_NervousFighter_Description",
    iconPath = PLACEHOLDER_ICON,
    source = "combat",
    generation = { group = "combat_temperament", weight = 8 },
    excludes = { "pnc_veteran" },
    effects = {
        personality = { bravery = -0.10, aggression = 0.03 },
        combat = { melee = {
            attackRateMultiplier = 1.08, windupTimeMultiplier = 0.94,
            hitChanceBias = -0.05, pressureAccuracyBias = -0.07,
        } },
    },
})

register({
    id = "pnc_patient",
    labelKey = "UI_PNC_Trait_Patient",
    descriptionKey = "UI_PNC_Trait_Patient_Description",
    iconPath = PLACEHOLDER_ICON,
    source = "combat",
    generation = { group = "combat_style", weight = 6 },
    excludes = { "pnc_hasty" },
    effects = {
        personality = { bravery = 0.05, aggression = -0.03 },
        combat = { melee = {
            attackRateMultiplier = 0.90, windupTimeMultiplier = 1.10,
            hitChanceBias = 0.06, pressureAccuracyBias = 0.06,
        } },
    },
})

register({
    id = "pnc_hasty",
    labelKey = "UI_PNC_Trait_Hasty",
    descriptionKey = "UI_PNC_Trait_Hasty_Description",
    iconPath = PLACEHOLDER_ICON,
    source = "combat",
    generation = { group = "combat_style", weight = 6 },
    excludes = { "pnc_patient" },
    effects = {
        personality = { aggression = 0.07, bravery = -0.02 },
        combat = { melee = {
            attackRateMultiplier = 1.14, windupTimeMultiplier = 0.86,
            hitChanceBias = -0.04, pressureAccuracyBias = -0.03,
        } },
    },
})

register({
    id = "pnc_scrapper",
    labelKey = "UI_PNC_Trait_Scrapper",
    descriptionKey = "UI_PNC_Trait_Scrapper_Description",
    iconPath = PLACEHOLDER_ICON,
    source = "combat",
    generation = { group = "combat_style", weight = 7 },
    effects = {
        personality = { aggression = 0.04, bravery = 0.02 },
        combat = { melee = {
            attackRateMultiplier = 1.08, windupTimeMultiplier = 0.96,
            hitChanceBias = 0.01, pressureAccuracyBias = 0.01,
        } },
    },
})

register({
    id = "pnc_peacemaker",
    labelKey = "UI_PNC_Trait_Peacemaker",
    descriptionKey = "UI_PNC_Trait_Peacemaker_Description",
    iconPath = PLACEHOLDER_ICON,
    source = "combat",
    generation = { group = "combat_style", weight = 5 },
    effects = {
        personality = { aggression = -0.08, bravery = 0.04 },
        combat = { melee = {
            attackRateMultiplier = 0.86, windupTimeMultiplier = 1.14,
            hitChanceBias = 0.03, pressureAccuracyBias = 0.05,
        } },
    },
})

return Traits
