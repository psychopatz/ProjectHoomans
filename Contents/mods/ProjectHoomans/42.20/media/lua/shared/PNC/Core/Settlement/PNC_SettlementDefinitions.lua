PNC = PNC or {}
PNC.SettlementDefinitions = PNC.SettlementDefinitions or {}

local Definitions = PNC.SettlementDefinitions

Definitions.SCHEMA_VERSION = 1
Definitions.STARTING_TERRITORY = 270
Definitions.TILES_PER_BARRICADE = 10
Definitions.HQ_LEVELS = Definitions.HQ_LEVELS or {
    [1] = { territoryLimit = 400, facilityTier = 1 },
    [2] = { territoryLimit = 500, facilityTier = 2,
        requirements = { previousLevel = 1 } },
    [3] = { territoryLimit = 650, facilityTier = 3,
        requirements = { previousLevel = 2 } },
}

function Definitions.GetHQLevel(level)
    return Definitions.HQ_LEVELS[math.max(1, math.floor(tonumber(level) or 1))]
end

function Definitions.GetTerritoryLimit(level)
    local definition = Definitions.GetHQLevel(level)
    return definition and definition.territoryLimit or 0
end

function Definitions.GetTerritoryCapacity(level, barricadeCount)
    return math.min(
        Definitions.STARTING_TERRITORY
            + math.max(0, math.floor(tonumber(barricadeCount) or 0))
                * Definitions.TILES_PER_BARRICADE,
        Definitions.GetTerritoryLimit(level)
    )
end

return Definitions
