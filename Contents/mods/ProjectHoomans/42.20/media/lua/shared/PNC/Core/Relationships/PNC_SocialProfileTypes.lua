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

function Types.OrientationFromKinsey(kinsey)
    local score = math.floor(finite(kinsey, 0) + 0.5)
    if score <= 1 then return Constants.ORIENTATION_STRAIGHT end
    if score >= 5 then return Constants.ORIENTATION_GAY end
    return Constants.ORIENTATION_BISEXUAL
end

function Types.NormalizeKinsey(value, orientationFallback)
    local defaultMap = Constants.KINSEY_DEFAULT_BY_ORIENTATION or {}
    local fallback = defaultMap[orientationFallback]
    if fallback == nil then fallback = 0 end
    if tonumber(value) == nil then return fallback end
    local score = math.floor(finite(value, fallback) + 0.5)
    local low = tonumber(Constants.KINSEY_MIN) or 0
    local high = tonumber(Constants.KINSEY_MAX) or 6
    return math.max(low, math.min(high, score))
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
    local orientation = Types.NormalizeEnum(
        source.orientation,
        Constants.VALID_ORIENTATIONS,
        nil
    )
    local kinsey
    if tonumber(source.kinsey) ~= nil then
        kinsey = Types.NormalizeKinsey(source.kinsey, orientation)
        orientation = orientation or Types.OrientationFromKinsey(kinsey)
    else
        orientation = orientation or Constants.ORIENTATION_STRAIGHT
        kinsey = Types.NormalizeKinsey(nil, orientation)
    end
    return {
        schemaVersion = Constants.PLAYER_PROFILE_SCHEMA_VERSION,
        revision = revision(source.revision),
        resolvedAt = timestamp(source.resolvedAt),
        orientation = orientation,
        kinsey = kinsey,
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
    if tonumber(source.kinsey) ~= nil then
        output.kinsey = Types.NormalizeKinsey(source.kinsey, output.orientation)
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
        overrides,
        nil
    )
end

function Types.NormalizeNPCPersonality(
    value,
    identitySeed,
    archetypeID,
    overrides,
    traitSource
)
    local source = type(value) == "table" and value or nil
    local normalizedOverrides =
        Types.NormalizeNPCPersonalityOverrides(overrides)
    local currentVersion = math.max(1, math.floor(finite(
        Constants.NPC_GENERATION_VERSION,
        1
    )))
    local sourceVersion = source and revision(source.generationVersion) or 0
    local hasTraitSource = type(traitSource) == "table"
    local currentTraitFingerprint = hasTraitSource
        and PNC.NPCTraitEffects
        and PNC.NPCTraitEffects.GetFingerprint
        and PNC.NPCTraitEffects.GetFingerprint(traitSource) or nil
    local sourceTraitFingerprint = source and tostring(
        source.traitFingerprint or "") or ""
    if currentTraitFingerprint == nil then
        currentTraitFingerprint = sourceTraitFingerprint
    end
    local sourceIsGenerated = not source
        or source.generatedFromSeed == true
        or (source.generatedFromSeed == nil and sourceVersion > 0)
    local shouldRegenerate = not source
        or (sourceIsGenerated and sourceVersion ~= currentVersion)
        or (hasTraitSource and sourceIsGenerated and sourceTraitFingerprint
            ~= currentTraitFingerprint)
    local generated = Generator.Generate(
        identitySeed,
        archetypeID,
        shouldRegenerate and normalizedOverrides or nil,
        traitSource
    )
    generated.traitFingerprint = currentTraitFingerprint
    local generationVersion
    local output
    local index
    local dimension
    if not source then
        return generated
    end
    if shouldRegenerate then
        return generated
    end
    generationVersion = sourceVersion
    local resolvedOrientation = Types.NormalizeEnum(
        source.orientation,
        Constants.VALID_ORIENTATIONS,
        generated.orientation
    )
    local resolvedKinsey = tonumber(source.kinsey) ~= nil
        and Types.NormalizeKinsey(source.kinsey, resolvedOrientation)
        or Types.NormalizeKinsey(nil, resolvedOrientation)
    output = {
        schemaVersion = Constants.NPC_PERSONALITY_SCHEMA_VERSION,
        orientation = resolvedOrientation,
        kinsey = resolvedKinsey,
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
        generatedFromSeed = sourceIsGenerated,
        generationVersion = generationVersion,
        traitFingerprint = sourceTraitFingerprint,
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
