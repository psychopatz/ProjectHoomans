if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyResearchService = PNC.ColonyResearchService or {}

local Service = PNC.ColonyResearchService
local Research = require "PNC/Core/Colony/Research/PNC_ColonyResearchDefinitions"
local StorageDefinitions = require "PNC/Core/Colony/Storage/PNC_ColonyStorageDefinitions"

function Service.BuildSnapshot(storage)
    if not storage then return { entries = {} } end
    local entries = {}
    for _, id in ipairs(Research.ORDER) do
        local definition = Research.Get(id)
        if definition and id == "storage_capacity" then
            local nextTier = StorageDefinitions.GetNextTier(storage.tier)
            entries[#entries + 1] = {
                id = id,
                category = definition.category,
                labelKey = definition.labelKey,
                currentLevel = storage.tier,
                maxLevel = definition.maxLevel,
                currentValue = StorageDefinitions.GetCapacity(storage.tier),
                nextLevel = nextTier,
                nextValue = nextTier
                    and StorageDefinitions.GetCapacity(nextTier) or nil,
                increase = nextTier
                    and StorageDefinitions.GetCapacity(nextTier)
                        - StorageDefinitions.GetCapacity(storage.tier) or nil,
            }
        end
    end
    local production = storage and storage.settlementId and PNC.ResearchService
        and PNC.ResearchService.Queries.BuildSnapshot(storage.settlementId)
        or { entries = {}, learnedRecipeIds = {} }
    for index = 1, #(production.entries or {}) do
        entries[#entries + 1] = production.entries[index]
    end
    production.entries = entries
    return production
end

function Service.DebugUpgrade(player, researchID, args)
    if researchID ~= "storage_capacity" then
        return false, "unknown_research"
    end
    return PNC.ColonyStorageService.DebugUpgrade(player, args)
end

return Service
