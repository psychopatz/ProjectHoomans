local Traits = PNC.NPCTraits
local Internal = Traits.Internal
local register = Internal.Register
local PLACEHOLDER_ICON = Internal.PlaceholderIcon

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

