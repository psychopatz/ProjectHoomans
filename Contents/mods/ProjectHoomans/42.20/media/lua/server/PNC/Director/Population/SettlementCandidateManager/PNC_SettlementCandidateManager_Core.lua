if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SettlementCandidates = PNC.SettlementCandidates or {}
PNC.SettlementCandidateManagerInternal =
    PNC.SettlementCandidateManagerInternal or {}

local Candidates = PNC.SettlementCandidates
local H = PNC.SettlementCandidateManagerInternal
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Locations = PNC.AbstractLocations
local Store = PNC.AbstractWorldStore
local Core = PNC.Core
local Log = PNC.PopulationLog

Candidates.Pools = Candidates.Pools or {}
Candidates.Reservations = Candidates.Reservations or {}
Candidates.Metrics = Candidates.Metrics or { discovered = 0, evaluated = 0,
    rejected = 0, reservations = 0, metaQueries = 0,
    metaMatched = 0, metaInspected = 0, metaDiscovered = 0,
    starterDiscovered = 0 }
for _, field in ipairs({ "discovered", "evaluated", "rejected",
    "reservations", "metaQueries", "metaMatched", "metaInspected",
    "metaDiscovered", "starterDiscovered" }) do
    Candidates.Metrics[field] = tonumber(Candidates.Metrics[field]) or 0
end
Candidates.LastEvaluations = Candidates.LastEvaluations or {}
Candidates.LastStarterDiscovery = Candidates.LastStarterDiscovery or {}
Candidates.LastMetaDiscovery = Candidates.LastMetaDiscovery or {}
Candidates.Cursors = Candidates.Cursors or {}

function H.PopulationData()
    Store.EnsureLoaded()
    return Store.Registry.population
end

function H.Add(location)
    if not location then return false end
    local sectorID = Sectors.IDForPosition(location.x, location.y)
    Candidates.Pools[sectorID] = Candidates.Pools[sectorID] or {}
    if Candidates.Pools[sectorID][location.id] then return false end
    Candidates.Pools[sectorID][location.id] = true
    Candidates.Metrics.discovered = Candidates.Metrics.discovered + 1
    return true
end

function Candidates.RegisterLocation(location) return H.Add(location) end

function Candidates.Rebuild()
    Candidates.Pools = {}
    for _, location in ipairs(Locations.List()) do H.Add(location) end
end

return Candidates

