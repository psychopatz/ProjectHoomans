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

function Candidates.DiscoverMeta(sectorID, seed, purpose)
    local sx, sy = Sectors.ParseID(sectorID)
    if not sx then return 0, { reason = "INVALID_SECTOR" } end
    local size = Config.SECTOR_SIZE
    local found, diagnostic = Locations.DiscoverMetaBuildingsInBounds({
        minX = sx * size, minY = sy * size,
        maxX = (sx + 1) * size - 1,
        maxY = (sy + 1) * size - 1,
    }, 0, seed, Config.STARTER_META_CANDIDATE_LIMIT,
        Config.STARTER_META_INSPECTION_LIMIT)
    diagnostic = diagnostic or { reason = "DISCOVERY_FAILED" }
    diagnostic.sectorId = sectorID
    diagnostic.seed = seed
    diagnostic.purpose = tostring(purpose or "POPULATION_FALLBACK")
    Candidates.Metrics.metaQueries = Candidates.Metrics.metaQueries + 1
    Candidates.Metrics.metaMatched = Candidates.Metrics.metaMatched
        + (tonumber(diagnostic.matched) or 0)
    Candidates.Metrics.metaInspected = Candidates.Metrics.metaInspected
        + (tonumber(diagnostic.inspected) or 0)
    for _, locationID in ipairs(diagnostic.locationIds or {}) do
        if H.Add(Locations.Get(locationID)) then
            Candidates.Metrics.metaDiscovered =
                Candidates.Metrics.metaDiscovered + 1
            if purpose == "STARTER" then
                Candidates.Metrics.starterDiscovered =
                    Candidates.Metrics.starterDiscovered + 1
            end
        end
    end
    Candidates.LastMetaDiscovery[sectorID] = Core.DeepCopy(diagnostic)
    if purpose == "STARTER" then
        Candidates.LastStarterDiscovery[sectorID] = Core.DeepCopy(diagnostic)
    end
    local fields = { sectorId = sectorID, purpose = diagnostic.purpose,
        seed = seed, reason = diagnostic.reason, found = diagnostic.found,
        matched = diagnostic.matched, inspected = diagnostic.inspected,
        residential = diagnostic.residential }
    if (tonumber(diagnostic.found) or 0) > 0 then
        Log.Info("META_SITE_DISCOVERY", fields)
    else
        Log.Warn("META_SITE_DISCOVERY", fields)
    end
    return found, diagnostic
end

function Candidates.DiscoverStarter(sectorID, seed)
    return Candidates.DiscoverMeta(sectorID, seed, "STARTER")
end

return Candidates

