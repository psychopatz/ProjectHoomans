if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyResearchService = PNC.ColonyResearchService or {}

local Service = PNC.ColonyResearchService
local function reconcileExistingProgression(storage)
    if not storage or not storage.settlementId or not PNC.ResearchService then
        return
    end
    local colonyId = storage.settlementId
    local factionId = storage.ownerFactionId
    local base = PNC.BaseService and PNC.BaseService.GetForColony
        and PNC.BaseService.GetForColony(colonyId) or nil
    for level = 2, math.max(1, tonumber(base and base.hqLevel) or 1) do
        PNC.ResearchService.Commands.UnlockTechnology(colonyId,
            "hq:" .. tostring(level), factionId)
    end
    for level = 2, math.max(1, tonumber(storage.tier) or 1) do
        PNC.ResearchService.Commands.UnlockTechnology(colonyId,
            "storage:" .. tostring(level), factionId)
    end
end

function Service.BuildSnapshot(storage)
    if not storage then return { entries = {} } end
    reconcileExistingProgression(storage)
    local entries = {}
    local production = storage and storage.settlementId and PNC.ResearchService
        and PNC.ResearchService.Queries.BuildSnapshot(storage.settlementId)
        or { entries = {}, learnedRecipeIds = {} }
    for index = 1, #(production.entries or {}) do
        entries[#entries + 1] = production.entries[index]
    end
    production.entries = entries
    return production
end

return Service
