PNC = PNC or {}
PNC.ColonyResearchDefinitions = PNC.ColonyResearchDefinitions or {}

local Research = PNC.ColonyResearchDefinitions

Research.ORDER = {
    "hq:2", "hq:3",
    "storage:2", "storage:3", "storage:4", "storage:5", "storage:6",
    "storage:7", "storage:8", "storage:9", "storage:10",
    "facility:workshop",
}
Research.BY_ID = {
    ["hq:2"] = {
        id = "hq:2", category = "settlement",
        labelKey = "UI_PNC_Research_HQ2", requiredWork = 80,
        requiredSkills = {{ skillId = "Carpentry", level = 2 }},
    },
    ["hq:3"] = {
        id = "hq:3", category = "settlement",
        labelKey = "UI_PNC_Research_HQ3", requiredWork = 140,
        requiredSkills = {{ skillId = "Carpentry", level = 4 }},
        prerequisiteTechnology = "hq:2",
    },
    ["facility:workshop"] = {
        id = "facility:workshop",
        category = "facilities",
        labelKey = "UI_PNC_Research_BasicWorkshop",
        descriptionKey = "UI_PNC_Research_BasicWorkshopDescription",
        requiredWork = 60,
        requiredSkills = {{ skillId = "Carpentry", level = 1 }},
    },
}

for level = 2, 10 do
    local id = "storage:" .. tostring(level)
    Research.BY_ID[id] = {
        id = id, category = "storage",
        labelKey = "UI_PNC_Research_Storage" .. tostring(level),
        requiredWork = 35 + level * 15,
        requiredSkills = {{ skillId = "Carpentry",
            level = math.min(5, math.floor(level / 2)) }},
        prerequisiteTechnology = level > 2
            and "storage:" .. tostring(level - 1) or nil,
    }
end

Research.POLICY = {
    consumeBlueprintOnCompletion = false,
    blueprintWorkMultiplier = 0.55,
    reverseEngineeringWorkMultiplier = 1.0,
}

function Research.Get(id)
    return Research.BY_ID[tostring(id or "")]
end

return Research
