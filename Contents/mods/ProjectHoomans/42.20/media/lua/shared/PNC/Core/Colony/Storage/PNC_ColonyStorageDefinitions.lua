PNC = PNC or {}
PNC.ColonyStorageDefinitions = PNC.ColonyStorageDefinitions or {}

local Definitions = PNC.ColonyStorageDefinitions

Definitions.SCHEMA_VERSION = 1
Definitions.MODDATA_KEY = "PNC_ColonyStorage_v1"
Definitions.PRIMARY_TYPE = "general_stockpile"
Definitions.PRIMARY = {
    initialTier = 1,
    baseCapacity = 200,
    capacityPerTier = 50,
    maxTier = 10,
}

function Definitions.NormalizeTier(value, definition)
    definition = definition or Definitions.PRIMARY
    return math.max(
        definition.initialTier,
        math.min(definition.maxTier, math.floor(tonumber(value)
            or definition.initialTier))
    )
end

function Definitions.GetCapacity(tier, definition)
    definition = definition or Definitions.PRIMARY
    tier = Definitions.NormalizeTier(tier, definition)
    return definition.baseCapacity
        + ((tier - definition.initialTier) * definition.capacityPerTier)
end

function Definitions.GetNextTier(tier, definition)
    definition = definition or Definitions.PRIMARY
    tier = Definitions.NormalizeTier(tier, definition)
    if tier >= definition.maxTier then return nil end
    return tier + 1
end

function Definitions.PrimaryStorageID(factionID)
    return "storage:" .. tostring(factionID or "") .. ":primary"
end

return Definitions
