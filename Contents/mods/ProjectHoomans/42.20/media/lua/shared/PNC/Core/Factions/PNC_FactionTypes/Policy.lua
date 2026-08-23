PNC = PNC or {}
PNC.FactionTypes = PNC.FactionTypes or {}
PNC.FactionTypes.Internal = PNC.FactionTypes.Internal or {}

local Types = PNC.FactionTypes
local Internal = Types.Internal
local Constants = PNC.FactionConstants
local Archetypes = PNC.FactionArchetypes
local DiplomacyMath = PNC.FactionDiplomacyMath

function Internal.Clamp(value, minimum, maximum)
    return DiplomacyMath and DiplomacyMath.Clamp
        and DiplomacyMath.Clamp(value, minimum, maximum)
        or math.max(minimum, math.min(maximum, Internal.Finite(value, 0)))
end

local function deterministicUnit(seedText)
    local hash = 2166136261
    local index
    seedText = tostring(seedText or "")
    for index = 1, #seedText do
        hash = (
            hash * 16777619
            + string.byte(seedText, index)
        ) % 2147483647
    end
    return (hash % 10001) / 10000
end

local function policyVariation(factionID, field)
    return (deterministicUnit(
        tostring(factionID) .. ":" .. tostring(field)
    ) * 0.16) - 0.08
end

function Types.NormalizePolicy(value, archetypeID, factionID)
    local source = type(value) == "table" and value or {}
    local defaults = Archetypes.GetPolicyDefaults(archetypeID)
        or {
            aggression = 0.5,
            retaliation = 0.5,
            caution = 0.5,
            hospitality = 0.5,
            opportunism = 0.5,
            outsiderPolicy = "neutral",
            warThreshold = 70,
            peaceThreshold = 25,
        }
    local function dimension(field)
        if source[field] ~= nil then
            return Internal.Clamp(source[field], 0, 1)
        end
        return Internal.Clamp(
            (tonumber(defaults[field]) or 0.5)
                + policyVariation(factionID, field),
            0,
            1
        )
    end
    local outsiderPolicy =
        Constants.VALID_OUTSIDER_POLICIES[
            source.outsiderPolicy
        ] and source.outsiderPolicy
        or defaults.outsiderPolicy
    return {
        schemaVersion = Constants.POLICY_SCHEMA_VERSION,
        aggression = dimension("aggression"),
        retaliation = dimension("retaliation"),
        caution = dimension("caution"),
        hospitality = dimension("hospitality"),
        opportunism = dimension("opportunism"),
        outsiderPolicy =
            Constants.VALID_OUTSIDER_POLICIES[
                outsiderPolicy
            ] and outsiderPolicy or "neutral",
        warThreshold = Internal.Clamp(
            source.warThreshold ~= nil
                and source.warThreshold
                or defaults.warThreshold,
            0,
            100
        ),
        peaceThreshold = Internal.Clamp(
            source.peaceThreshold ~= nil
                and source.peaceThreshold
                or defaults.peaceThreshold,
            0,
            100
        ),
        generatedFromArchetype =
            source.generatedFromArchetype ~= false,
        generationVersion =
            Constants.POLICY_GENERATION_VERSION,
    }
end

function Types.NewPolicy(archetypeID, factionID, overrides)
    return Types.NormalizePolicy(
        overrides,
        archetypeID,
        factionID
    )
end
