local Types = PNC.AbstractWorldTypes
local Internal = Types.Internal
local Config = PNC.DirectorConfig

local function normalizeOccupants(source)
    local occupants = {}
    local groupID
    local visit
    local raw = type(source.occupants) == "table"
        and source.occupants.groups or {}
    for groupID, visit in pairs(raw) do
        if Internal.SafeID(groupID, "agroup_")
            and type(visit) == "table"
        then
            occupants[groupID] = {
                arrivedAt = math.max(
                    0,
                    Internal.Finite(visit.arrivedAt, 0)
                ),
                plannedDepartureAt = math.max(
                    0,
                    Internal.Finite(visit.plannedDepartureAt, 0)
                ),
            }
        end
    end
    return occupants
end

local function normalizePopulationHistory(value)
    if type(value) ~= "table" then return nil end
    return {
        formerSettlement = value.formerSettlement == true,
        destroyedAt = math.max(
            0,
            Internal.Finite(value.destroyedAt, 0)
        ),
        regenerationBlockedUntil = math.max(
            0,
            Internal.Finite(value.regenerationBlockedUntil, 0)
        ),
    }
end

function Types.NormalizeLocation(value, locationID)
    local source = type(value) == "table" and value or {}
    local id = Internal.SafeID(locationID or source.id, "aloc_")
    if not id then return nil end
    return {
        schemaVersion = Config.SCHEMA_VERSION,
        id = id,
        type = Config.LOCATION_TYPES[source.type]
            and source.type or "TEMPORARY",
        x = Internal.Finite(source.x, 0),
        y = Internal.Finite(source.y, 0),
        z = Internal.Finite(source.z, 0),
        tags = Internal.StringSet(source.tags),
        resourcePotential = Internal.Resources(source.resourcePotential),
        scavengedLevel = math.max(
            0,
            math.min(100, Internal.Finite(source.scavengedLevel, 0))
        ),
        danger = math.max(
            0,
            math.min(100, Internal.Finite(source.danger, 0))
        ),
        occupants = { groups = normalizeOccupants(source) },
        visitHistory = type(source.visitHistory) == "table"
            and Internal.Copy(source.visitHistory) or {},
        sourceSite = type(source.sourceSite) == "table"
            and Internal.Copy(source.sourceSite) or nil,
        populationHistory = normalizePopulationHistory(
            source.populationHistory
        ),
        revision = Internal.Integer(
            source.revision, 0, 2147483647, 0
        ),
    }
end
