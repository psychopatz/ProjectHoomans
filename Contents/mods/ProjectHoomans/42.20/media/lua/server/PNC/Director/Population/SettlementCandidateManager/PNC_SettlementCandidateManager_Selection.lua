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

function Candidates.Best(sectorID, factionArchetypeID, resolved, now, budget,
    seed, metaAttempted)
    Candidates.Discover(sectorID, budget)
    if Candidates.PoolCount(sectorID) == 0 and seed and not metaAttempted then
        Candidates.DiscoverMeta(sectorID, seed, "SETTLEMENT_FALLBACK")
        metaAttempted = true
    end
    local values = {}
    for locationID in pairs(Candidates.Pools[sectorID] or {}) do
        values[#values + 1] = locationID
    end
    table.sort(values)
    budget = math.max(1, math.floor(tonumber(budget)
        or Config.CANDIDATE_EVALUATION_BUDGET))
    local best, evaluated = nil, {}
    local start = math.max(1, math.min(#values,
        tonumber(Candidates.Cursors[sectorID]) or 1))
    for offset = 0, math.min(#values, budget) - 1 do
        local index = ((start - 1 + offset) % #values) + 1
        local result = Candidates.Evaluate(values[index], factionArchetypeID,
            resolved, now, nil, seed)
        evaluated[#evaluated + 1] = result
        if result.eligible and (not best or result.score > best.score
            or result.score == best.score
                and result.locationId < best.locationId) then best = result end
    end
    if #values > 0 then
        Candidates.Cursors[sectorID] = ((start - 1 + math.min(#values, budget))
            % #values) + 1
    end
    Candidates.LastEvaluations[sectorID] = evaluated
    if not best and seed and not metaAttempted then
        Candidates.DiscoverMeta(sectorID, seed, "SETTLEMENT_FALLBACK")
        return Candidates.Best(sectorID, factionArchetypeID, resolved, now,
            budget, seed, true)
    end
    return best, evaluated
end

function Candidates.PoolCount(sectorID)
    local total = 0
    for _ in pairs(Candidates.Pools[tostring(sectorID or "")] or {}) do
        total = total + 1
    end
    return total
end

return Candidates

