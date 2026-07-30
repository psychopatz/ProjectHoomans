-- Shared, data-only constants for player social profiles and NPC personality.

PNC = PNC or {}
PNC.SocialProfileConstants = PNC.SocialProfileConstants or {}
PNC.Config = PNC.Config or {}
PNC.Config.Relationships = PNC.Config.Relationships or {}

local Constants = PNC.SocialProfileConstants
local Config = PNC.Config.Relationships

Constants.PLAYER_PROFILE_SCHEMA_VERSION = 1
Constants.NPC_PERSONALITY_SCHEMA_VERSION = 1
Constants.NPC_GENERATION_VERSION = 1

Constants.ORIENTATION_STRAIGHT = "straight"
Constants.ORIENTATION_GAY = "gay"
Constants.ORIENTATION_BISEXUAL = "bisexual"
Constants.VALID_ORIENTATIONS = {
    straight = true,
    gay = true,
    bisexual = true,
}

Constants.FOOD_NEUTRAL = "neutral"
Constants.FOOD_BLAND = "bland"
Constants.FOOD_SPICY = "spicy"
Constants.VALID_FOOD_PREFERENCES = {
    neutral = true,
    bland = true,
    spicy = true,
}

Constants.ROMANCE_NEUTRAL = "neutral"
Constants.ROMANCE_FLIRTY = "flirty"
Constants.ROMANCE_RESERVED = "reserved"
Constants.VALID_ROMANCE_STYLES = {
    neutral = true,
    flirty = true,
    reserved = true,
}

Constants.JEALOUSY_NORMAL = "normal"
Constants.JEALOUSY_JEALOUS = "jealous"
Constants.JEALOUSY_UNPOSSESSIVE = "unpossessive"
Constants.VALID_JEALOUSY_STYLES = {
    normal = true,
    jealous = true,
    unpossessive = true,
}

Constants.SOCIAL_NEUTRAL = "neutral"
Constants.SOCIAL_FRIENDLY = "friendly"
Constants.SOCIAL_WITHDRAWN = "withdrawn"
Constants.VALID_SOCIAL_STYLES = {
    neutral = true,
    friendly = true,
    withdrawn = true,
}

Constants.NUMERIC_DIMENSIONS = {
    "compassion",
    "sociability",
    "forgiveness",
    "bravery",
    "materialism",
    "aggression",
    "loyalty",
}

Constants.TRAIT_IDS = {
    GAY = "PNC_Gay",
    BISEXUAL = "PNC_Bisexual",
    BLAND_PALATE = "PNC_BlandPalate",
    SPICE_LOVER = "PNC_SpiceLover",
    FLIRTY = "PNC_Flirty",
    RESERVED = "PNC_Reserved",
    JEALOUS = "PNC_Jealous",
    UNPOSSESSIVE = "PNC_Unpossessive",
    FRIENDLY = "PNC_Friendly",
    WITHDRAWN = "PNC_Withdrawn",
}

local T = Constants.TRAIT_IDS

-- Build 42 ResourceLocation values are lower-cased by the engine. The
-- canonical PNC IDs remain stable primitive values in persistent profiles.
Constants.TRAIT_DEFINITIONS = {
    {
        id = T.GAY,
        resource = "pnc:pnc_gay",
        cost = 0,
        uiName = "UI_PNC_Trait_Gay",
        uiDescription = "UI_PNC_Trait_Gay_Description",
        excludes = T.BISEXUAL,
    },
    {
        id = T.BISEXUAL,
        resource = "pnc:pnc_bisexual",
        cost = 0,
        uiName = "UI_PNC_Trait_Bisexual",
        uiDescription = "UI_PNC_Trait_Bisexual_Description",
        excludes = T.GAY,
    },
    {
        id = T.BLAND_PALATE,
        resource = "pnc:pnc_blandpalate",
        cost = 0,
        uiName = "UI_PNC_Trait_BlandPalate",
        uiDescription = "UI_PNC_Trait_BlandPalate_Description",
        excludes = T.SPICE_LOVER,
    },
    {
        id = T.SPICE_LOVER,
        resource = "pnc:pnc_spicelover",
        cost = 0,
        uiName = "UI_PNC_Trait_SpiceLover",
        uiDescription = "UI_PNC_Trait_SpiceLover_Description",
        excludes = T.BLAND_PALATE,
    },
    {
        id = T.FLIRTY,
        resource = "pnc:pnc_flirty",
        cost = 0,
        uiName = "UI_PNC_Trait_Flirty",
        uiDescription = "UI_PNC_Trait_Flirty_Description",
        excludes = T.RESERVED,
    },
    {
        id = T.RESERVED,
        resource = "pnc:pnc_reserved",
        cost = 0,
        uiName = "UI_PNC_Trait_Reserved",
        uiDescription = "UI_PNC_Trait_Reserved_Description",
        excludes = T.FLIRTY,
    },
    {
        id = T.JEALOUS,
        resource = "pnc:pnc_jealous",
        cost = 0,
        uiName = "UI_PNC_Trait_Jealous",
        uiDescription = "UI_PNC_Trait_Jealous_Description",
        excludes = T.UNPOSSESSIVE,
    },
    {
        id = T.UNPOSSESSIVE,
        resource = "pnc:pnc_unpossessive",
        cost = 0,
        uiName = "UI_PNC_Trait_Unpossessive",
        uiDescription = "UI_PNC_Trait_Unpossessive_Description",
        excludes = T.JEALOUS,
    },
    {
        id = T.FRIENDLY,
        resource = "pnc:pnc_friendly",
        -- Build 42 displays a positive Cost as points spent.
        cost = 2,
        uiName = "UI_PNC_Trait_Friendly",
        uiDescription = "UI_PNC_Trait_Friendly_Description",
        excludes = T.WITHDRAWN,
    },
    {
        id = T.WITHDRAWN,
        resource = "pnc:pnc_withdrawn",
        -- Build 42 displays a negative Cost as points granted.
        cost = -2,
        uiName = "UI_PNC_Trait_Withdrawn",
        uiDescription = "UI_PNC_Trait_Withdrawn_Description",
        excludes = T.FRIENDLY,
    },
}

Constants.EXCLUSION_GROUPS = {
    { T.GAY, T.BISEXUAL },
    { T.BLAND_PALATE, T.SPICE_LOVER },
    { T.FLIRTY, T.RESERVED },
    { T.JEALOUS, T.UNPOSSESSIVE },
    { T.FRIENDLY, T.WITHDRAWN },
}

-- Deterministic precedence for malformed/external trait combinations.
Constants.TRAIT_PRECEDENCE = {
    { preferred = T.BISEXUAL, discarded = T.GAY },
    { preferred = T.SPICE_LOVER, discarded = T.BLAND_PALATE },
    { preferred = T.RESERVED, discarded = T.FLIRTY },
    { preferred = T.JEALOUS, discarded = T.UNPOSSESSIVE },
    { preferred = T.FRIENDLY, discarded = T.WITHDRAWN },
}

Constants.DEFAULT_ORIENTATION_WEIGHTS = {
    straight = 80,
    gay = 10,
    bisexual = 10,
}
Constants.DEFAULT_CATEGORY_WEIGHTS = {
    foodPreference = { neutral = 60, bland = 20, spicy = 20 },
    romanceStyle = { neutral = 60, flirty = 20, reserved = 20 },
    jealousyStyle = { normal = 60, jealous = 20, unpossessive = 20 },
    socialStyle = { neutral = 60, friendly = 20, withdrawn = 20 },
}

Constants.ARCHETYPE_MODIFIERS = {
    Doctor = {
        compassion = 0.10,
        aggression = -0.05,
        materialism = -0.05,
    },
    Foreman = {
        loyalty = 0.05,
        sociability = 0.05,
    },
    Mechanic = {
        materialism = 0.05,
        sociability = -0.02,
    },
    General = {},
}

if Config.DebugSocialProfiles == nil then
    Config.DebugSocialProfiles = false
end
if Config.DebugSocialEvents == nil then
    Config.DebugSocialEvents = false
end
if Config.NPCOrientationWeights == nil then
    Config.NPCOrientationWeights = {
        straight = Constants.DEFAULT_ORIENTATION_WEIGHTS.straight,
        gay = Constants.DEFAULT_ORIENTATION_WEIGHTS.gay,
        bisexual = Constants.DEFAULT_ORIENTATION_WEIGHTS.bisexual,
    }
end

return Constants
