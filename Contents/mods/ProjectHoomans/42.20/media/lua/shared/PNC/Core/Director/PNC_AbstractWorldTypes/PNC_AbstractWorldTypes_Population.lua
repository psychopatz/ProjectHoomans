local Types = PNC.AbstractWorldTypes
local Internal = Types.Internal
local Config = PNC.DirectorConfig

local function normalizeSectors(source, output)
    local id
    local raw
    for id, raw in pairs(
        type(source.sectors) == "table" and source.sectors or {}
    ) do
        if Internal.SafeID(id, "psector_") and type(raw) == "table" then
            output[id] = {
                id = id,
                discovered = raw.discovered == true,
                hadGroups = raw.hadGroups == true,
                hadSettlements = raw.hadSettlements == true,
                groupGenerationCooldownUntil = math.max(
                    0,
                    Internal.Finite(raw.groupGenerationCooldownUntil, 0)
                ),
                settlementGenerationCooldownUntil = math.max(
                    0,
                    Internal.Finite(
                        raw.settlementGenerationCooldownUntil,
                        0
                    )
                ),
                lastReconciledAt = math.max(
                    0,
                    Internal.Finite(raw.lastReconciledAt, 0)
                ),
            }
        end
    end
end

local function normalizeSiteHistory(source, output)
    local locationID
    local raw
    for locationID, raw in pairs(
        type(source.siteHistory) == "table" and source.siteHistory or {}
    ) do
        if Internal.SafeID(locationID, "aloc_")
            and type(raw) == "table"
        then
            output[locationID] = {
                formerSettlement = raw.formerSettlement == true,
                destroyedAt = math.max(
                    0,
                    Internal.Finite(raw.destroyedAt, 0)
                ),
                regenerationBlockedUntil = math.max(
                    0,
                    Internal.Finite(raw.regenerationBlockedUntil, 0)
                ),
            }
        end
    end
end

local function normalizeProvenance(source, output)
    local entityID
    local raw
    local normalized
    for entityID, raw in pairs(
        type(source.provenance) == "table" and source.provenance or {}
    ) do
        normalized = Internal.Generation(raw)
        if Internal.SafeID(entityID) and normalized then
            output[entityID] = normalized
        end
    end
end

local function normalizeCommitted(source, output)
    local order = Internal.IDArray(source.committedOrder)
    local limit = Config.Population.COMMITTED_GENERATION_HISTORY_LIMIT
    local first = math.max(1, #order - limit + 1)
    local index
    local id
    for index = first, #order do
        id = order[index]
        if source.committedGenerationIds
            and source.committedGenerationIds[id] == true
        then
            output.committedOrder[#output.committedOrder + 1] = id
            output.committedGenerationIds[id] = true
        end
    end
end

function Types.NormalizePopulation(value)
    local source = type(value) == "table" and value or {}
    local output = {
        nextGenerationSerial = Internal.Integer(
            source.nextGenerationSerial, 1, 2147483647, 1
        ),
        bootstrapCompleted = source.bootstrapCompleted == true,
        bootstrapCompletedAt = math.max(
            0,
            Internal.Finite(source.bootstrapCompletedAt, 0)
        ),
        starterSettlementId = Internal.SafeID(source.starterSettlementId),
        starterAttempts = Internal.Integer(
            source.starterAttempts, 0, 2147483647, 0
        ),
        worldSeed = Internal.Integer(
            source.worldSeed, 0, 2147483647, 0
        ),
        worldSeedString = type(source.worldSeedString) == "string"
            and string.sub(source.worldSeedString, 1, 128) or nil,
        sectors = {},
        siteHistory = {},
        provenance = {},
        committedGenerationIds = {},
        committedOrder = {},
    }
    normalizeSectors(source, output.sectors)
    normalizeSiteHistory(source, output.siteHistory)
    normalizeProvenance(source, output.provenance)
    normalizeCommitted(source, output)
    return output
end
