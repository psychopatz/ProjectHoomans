PNC = PNC or {}
PNC.ColonyResearchDefinitions = PNC.ColonyResearchDefinitions or {}

local Research = PNC.ColonyResearchDefinitions

Research.ORDER = { "facility:workshop", "storage_capacity" }
Research.BY_ID = {
    ["facility:workshop"] = {
        id = "facility:workshop",
        category = "facilities",
        labelKey = "UI_PNC_Research_BasicWorkshop",
        descriptionKey = "UI_PNC_Research_BasicWorkshopDescription",
        requiredWork = 60,
        requiredSkills = {{ skillId = "Carpentry", level = 1 }},
    },
    storage_capacity = {
        id = "storage_capacity",
        category = "storage",
        labelKey = "UI_PNC_Research_StorageCapacity",
        maxLevel = 10,
        storageType = "general_stockpile",
    },
}

Research.POLICY = {
    consumeBlueprintOnCompletion = false,
    blueprintWorkMultiplier = 0.55,
    reverseEngineeringWorkMultiplier = 1.0,
}

function Research.Get(id)
    return Research.BY_ID[tostring(id or "")]
end

return Research
