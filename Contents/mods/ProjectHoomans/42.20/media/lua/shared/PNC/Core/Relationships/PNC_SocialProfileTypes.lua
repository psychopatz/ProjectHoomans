-- Pure constructors and defensive normalizers for persistent social profiles.

PNC = PNC or {}
PNC.SocialProfileTypes = PNC.SocialProfileTypes or {}

local Types = PNC.SocialProfileTypes
local Constants = PNC.SocialProfileConstants
local Generator = PNC.SocialProfileGenerator

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        value = tonumber(fallback)
    end
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        value = 0
    end
    return value
end

local function revision(value)
    return math.max(0, math.floor(finite(value, 0)))
end

local function timestamp(value)
    return math.max(0, finite(value, 0))
end

function Types.NormalizeEnum(value, allowed, fallback)
    value = type(value) == "string" and value or nil
    return value and allowed[value] and value or fallback
end

function Types.NormalizeUnitValue(value, fallback)
    return math.max(0, math.min(1, finite(value, fallback or 0.5)))
end

local function normalizeSourceTraits(value)
    local output = {}
    local key
    local canonical
    if type(value) ~= "table" then
        return output
    end
    for key, enabled in pairs(value) do
        if enabled == true and PNC.SocialTraits
            and PNC.SocialTraits.NormalizeTraitID
        then
            canonical = PNC.SocialTraits.NormalizeTraitID(key)
            if canonical then
                output[canonical] = true
            end
        end
    end
    return output
end

function Types.NewPlayerSocialProfile(value)
    return Types.NormalizePlayerSocialProfile(value)
end

function Types.NormalizePlayerSocialProfile(value)
    local source = type(value) == "table" and value or {}
    return {
        schemaVersion = Constants.PLAYER_PROFILE_SCHEMA_VERSION,
        revision = revision(source.revision),
        resolvedAt = timestamp(source.resolvedAt),
        orientation = Types.NormalizeEnum(
            source.orientation,
            Constants.VALID_ORIENTATIONS,
            Constants.ORIENTATION_STRAIGHT
        ),
        foodPreference = Types.NormalizeEnum(
            source.foodPreference,
            Constants.VALID_FOOD_PREFERENCES,
            Constants.FOOD_NEUTRAL
        ),
        romanceStyle = Types.NormalizeEnum(
            source.romanceStyle,
            Constants.VALID_ROMANCE_STYLES,
            Constants.ROMANCE_NEUTRAL
        ),
        jealousyStyle = Types.NormalizeEnum(
            source.jealousyStyle,
            Constants.VALID_JEALOUSY_STYLES,
            Constants.JEALOUSY_NORMAL
        ),
        socialStyle = Types.NormalizeEnum(
            source.socialStyle,
            Constants.VALID_SOCIAL_STYLES,
            Constants.SOCIAL_NEUTRAL
        ),
        sourceTraits = normalizeSourceTraits(source.sourceTraits),
    }
end

function Types.NormalizeNPCPersonalityOverrides(value)
    local source = type(value) == "table" and value or {}
    local output = {}
    local index
    local dimension
    local numeric
    local enumFields = {
        orientation = Constants.VALID_ORIENTATIONS,
        foodPreference = Constants.VALID_FOOD_PREFERENCES,
        romanceStyle = Constants.VALID_ROMANCE_STYLES,
        jealousyStyle = Constants.VALID_JEALOUSY_STYLES,
        socialStyle = Constants.VALID_SOCIAL_STYLES,
    }
    local key
    local allowed
    for key, allowed in pairs(enumFields) do
        if type(source[key]) == "string" and allowed[source[key]] then
            output[key] = source[key]
        end
    end
    for index = 1, #Constants.NUMERIC_DIMENSIONS do
        dimension = Constants.NUMERIC_DIMENSIONS[index]
        numeric = tonumber(source[dimension])
        if numeric ~= nil
            and numeric == numeric
            and numeric ~= math.huge
            and numeric ~= -math.huge
        then
            output[dimension] = Types.NormalizeUnitValue(numeric, 0.5)
        end
    end
    return output
end

function Types.NewNPCPersonality(identitySeed, archetypeID, overrides)
    return Types.NormalizeNPCPersonality(
        nil,
        identitySeed,
        archetypeID,
        overrides
    )
end

function Types.NormalizeNPCPersonality(
    value,
    identitySeed,
    archetypeID,
    overrides
)
    local source = type(value) == "table" and value or nil
    local normalizedOverrides =
        Types.NormalizeNPCPersonalityOverrides(overrides)
    local generated = Generator.Generate(
        identitySeed,
        archetypeID,
        source and nil or normalizedOverrides
    )
    local generationVersion
    local output
    local index
    local dimension
    if not source then
        return generated
    end
    generationVersion = math.max(
        1,
        math.floor(finite(
            source.generationVersion,
            Constants.NPC_GENERATION_VERSION
        ))
    )
    output = {
        schemaVersion = Constants.NPC_PERSONALITY_SCHEMA_VERSION,
        orientation = Types.NormalizeEnum(
            source.orientation,
            Constants.VALID_ORIENTATIONS,
            generated.orientation
        ),
        foodPreference = Types.NormalizeEnum(
            source.foodPreference,
            Constants.VALID_FOOD_PREFERENCES,
            generated.foodPreference
        ),
        romanceStyle = Types.NormalizeEnum(
            source.romanceStyle,
            Constants.VALID_ROMANCE_STYLES,
            generated.romanceStyle
        ),
        jealousyStyle = Types.NormalizeEnum(
            source.jealousyStyle,
            Constants.VALID_JEALOUSY_STYLES,
            generated.jealousyStyle
        ),
        socialStyle = Types.NormalizeEnum(
            source.socialStyle,
            Constants.VALID_SOCIAL_STYLES,
            generated.socialStyle
        ),
        generatedFromSeed = source.generatedFromSeed ~= false,
        generationVersion = generationVersion,
    }
    for index = 1, #Constants.NUMERIC_DIMENSIONS do
        dimension = Constants.NUMERIC_DIMENSIONS[index]
        output[dimension] = Types.NormalizeUnitValue(
            source[dimension],
            generated[dimension]
        )
    end
    return output
end

return Types
