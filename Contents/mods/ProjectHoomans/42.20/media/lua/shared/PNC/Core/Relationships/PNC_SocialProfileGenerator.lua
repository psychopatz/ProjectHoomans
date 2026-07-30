-- Pure deterministic NPC personality generation. No engine clocks or RNG.

PNC = PNC or {}
PNC.SocialProfileGenerator = PNC.SocialProfileGenerator or {}

local Generator = PNC.SocialProfileGenerator
local Constants = PNC.SocialProfileConstants
local Identity = PNC.Identity

local function finite(value)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        return nil
    end
    return value
end

local function clampUnit(value, fallback)
    value = finite(value)
    if value == nil then
        value = finite(fallback) or 0.5
    end
    return math.max(0, math.min(1, value))
end

local function round4(value)
    return math.floor(clampUnit(value) * 10000 + 0.5) / 10000
end

local function normalizeWeight(value, fallback)
    value = finite(value)
    if value == nil then
        value = finite(fallback) or 0
    end
    return math.max(0, value)
end

local function weightedChoice(seed, salt, order, weights)
    local total = 0
    local index
    local value
    for index = 1, #order do
        total = total + normalizeWeight(weights[order[index]], 0)
    end
    if total <= 0 then
        return order[1]
    end
    value = Identity.Float(seed, salt) * total
    total = 0
    for index = 1, #order do
        total = total + normalizeWeight(weights[order[index]], 0)
        if value < total then
            return order[index]
        end
    end
    return order[#order]
end

local function orientationWeights()
    local defaults = Constants.DEFAULT_ORIENTATION_WEIGHTS
    local configured = PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships.NPCOrientationWeights or {}
    return {
        straight = normalizeWeight(
            configured.straight,
            defaults.straight
        ),
        gay = normalizeWeight(configured.gay, defaults.gay),
        bisexual = normalizeWeight(
            configured.bisexual,
            defaults.bisexual
        ),
    }
end

local function validOverride(overrides, key, allowed)
    local value = type(overrides) == "table" and overrides[key] or nil
    return allowed[value] and value or nil
end

function Generator.Generate(identitySeed, archetypeID, overrides)
    local seed = Identity.NormalizeSeed(identitySeed, archetypeID)
    local archetype = tostring(archetypeID or "General")
    local version = Constants.NPC_GENERATION_VERSION
    local saltPrefix = "social_profile:v" .. tostring(version) .. ":"
    local modifiers = Constants.ARCHETYPE_MODIFIERS[archetype] or {}
    local dimensions = {}
    local profile
    local index
    local dimension
    local override

    for index = 1, #Constants.NUMERIC_DIMENSIONS do
        dimension = Constants.NUMERIC_DIMENSIONS[index]
        dimensions[dimension] = round4(
            0.25
            + Identity.Float(seed, saltPrefix .. dimension) * 0.50
            + (finite(modifiers[dimension]) or 0)
        )
        override = type(overrides) == "table"
            and finite(overrides[dimension]) or nil
        if override ~= nil then
            dimensions[dimension] = round4(override)
        end
    end

    profile = {
        schemaVersion = Constants.NPC_PERSONALITY_SCHEMA_VERSION,
        orientation = weightedChoice(
            seed,
            saltPrefix .. "orientation",
            { "straight", "gay", "bisexual" },
            orientationWeights()
        ),
        foodPreference = weightedChoice(
            seed,
            saltPrefix .. "foodPreference",
            { "neutral", "bland", "spicy" },
            Constants.DEFAULT_CATEGORY_WEIGHTS.foodPreference
        ),
        romanceStyle = weightedChoice(
            seed,
            saltPrefix .. "romanceStyle",
            { "neutral", "flirty", "reserved" },
            Constants.DEFAULT_CATEGORY_WEIGHTS.romanceStyle
        ),
        jealousyStyle = weightedChoice(
            seed,
            saltPrefix .. "jealousyStyle",
            { "normal", "jealous", "unpossessive" },
            Constants.DEFAULT_CATEGORY_WEIGHTS.jealousyStyle
        ),
        socialStyle = weightedChoice(
            seed,
            saltPrefix .. "socialStyle",
            { "neutral", "friendly", "withdrawn" },
            Constants.DEFAULT_CATEGORY_WEIGHTS.socialStyle
        ),
        compassion = dimensions.compassion,
        sociability = dimensions.sociability,
        forgiveness = dimensions.forgiveness,
        bravery = dimensions.bravery,
        materialism = dimensions.materialism,
        aggression = dimensions.aggression,
        loyalty = dimensions.loyalty,
        generatedFromSeed = true,
        generationVersion = version,
    }

    profile.orientation = validOverride(
        overrides,
        "orientation",
        Constants.VALID_ORIENTATIONS
    ) or profile.orientation
    profile.foodPreference = validOverride(
        overrides,
        "foodPreference",
        Constants.VALID_FOOD_PREFERENCES
    ) or profile.foodPreference
    profile.romanceStyle = validOverride(
        overrides,
        "romanceStyle",
        Constants.VALID_ROMANCE_STYLES
    ) or profile.romanceStyle
    profile.jealousyStyle = validOverride(
        overrides,
        "jealousyStyle",
        Constants.VALID_JEALOUSY_STYLES
    ) or profile.jealousyStyle
    profile.socialStyle = validOverride(
        overrides,
        "socialStyle",
        Constants.VALID_SOCIAL_STYLES
    ) or profile.socialStyle
    return profile
end

return Generator
