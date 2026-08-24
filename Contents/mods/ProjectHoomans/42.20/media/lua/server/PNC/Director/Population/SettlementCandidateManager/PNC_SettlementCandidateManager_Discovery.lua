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

function Candidates.Discover(sectorID, budget)
    local center = Sectors.Center(sectorID)
    if not center then return 0 end
    budget = math.max(1, math.floor(tonumber(budget)
        or Config.CANDIDATE_EVALUATION_BUDGET))
    Locations.DiscoverLoadedNear(center.x, center.y, center.z,
        Config.SECTOR_SIZE * 0.75, budget)
    local found = 0
    for _, entry in ipairs(Locations.GetNearby(center.x, center.y,
        Config.SECTOR_SIZE * 0.75, budget * 4)) do
        if Sectors.IDForPosition(entry.location.x, entry.location.y) == sectorID
            and H.Add(entry.location) then found = found + 1 end
    end
    return found
end

return Candidates

