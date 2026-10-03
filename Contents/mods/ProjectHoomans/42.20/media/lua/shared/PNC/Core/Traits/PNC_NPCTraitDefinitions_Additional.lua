local Traits = PNC.NPCTraits
local Internal = Traits.Internal
local register = Internal.Register
local PLACEHOLDER_ICON = Internal.PlaceholderIcon

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
