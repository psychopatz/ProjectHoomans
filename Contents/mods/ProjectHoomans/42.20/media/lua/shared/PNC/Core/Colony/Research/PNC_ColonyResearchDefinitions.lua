PNC = PNC or {}
PNC.ColonyResearchDefinitions = PNC.ColonyResearchDefinitions or {}

local Research = PNC.ColonyResearchDefinitions

Research.ORDER = { "storage_capacity" }
Research.BY_ID = {
    storage_capacity = {
        id = "storage_capacity",
        category = "storage",
        labelKey = "UI_PNC_Research_StorageCapacity",
        maxLevel = 10,
        storageType = "general_stockpile",
    },
}

function Research.Get(id)
    return Research.BY_ID[tostring(id or "")]
end

return Research
