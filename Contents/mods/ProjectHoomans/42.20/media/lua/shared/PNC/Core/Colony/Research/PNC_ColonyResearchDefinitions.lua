PNC = PNC or {}
PNC.ColonyResearchDefinitions = PNC.ColonyResearchDefinitions or {}

local Research = PNC.ColonyResearchDefinitions

Research.ORDER = {
    "hq:2", "hq:3",
    "storage:2", "storage:3", "storage:4", "storage:5", "storage:6",
    "storage:7", "storage:8", "storage:9", "storage:10",
    "facility:workshop",
    "utility:water_collector:1", "utility:water_collector:2",
    "utility:water_collector:3", "utility:water_collector:4",
    "utility:water_collector:5", "utility:water_collector:6",
    "utility:water_collector:7", "utility:water_collector:8",
    "utility:water_collector:9", "utility:water_collector:10",
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

for level = 1, 10 do
    local id = "utility:water_collector:" .. tostring(level)
    Research.BY_ID[id] = {
        id = id, category = "utilities",
        labelKey = "UI_PNC_Research_WaterCollector" .. tostring(level),
        requiredWork = 45 + level * 20,
        requiredSkills = {{ skillId = "MetalWelding",
            level = math.min(5, math.floor((level + 1) / 2)) }},
        prerequisiteTechnology = level > 1
            and "utility:water_collector:" .. tostring(level - 1) or nil,
        researchCapability = "work.reverse",
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
