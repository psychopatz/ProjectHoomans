PNC = PNC or {}
PNC.FacilityDefinitions = PNC.FacilityDefinitions or {}

local Definitions = PNC.FacilityDefinitions
Definitions.SCHEMA_VERSION = 1
Definitions.ByID = Definitions.ByID or {}

Definitions.ComponentIconPaths = Definitions.ComponentIconPaths or {
    ["sleep.area"] = "media/ui/Facilities/Components/chair.png",
    ["sleep.bed"] = "media/ui/Facilities/Components/bed/barracks.png",
    ["farm.field"] = "media/ui/Facilities/Components/default.png",
    ["work.research"] =
        "media/ui/Facilities/Components/research_station/research_station.png",
    ["work.blueprint"] =
        "media/ui/Facilities/Components/research_station/architect_table.png",
    ["work.reverse"] =
        "media/ui/Facilities/Components/research_station/Lab_Station.png",
    ["work.craft"] =
        "media/ui/Facilities/Components/workshop/workbench.png",
    ["work.disassemble"] =
        "media/ui/Facilities/Components/workshop/recycling_bench.png",
    ["water.spigot"] =
        "media/ui/Facilities/Components/water_station/pump_spigot.png",
    ["water.tank"] = "media/ui/Facilities/Components/default.png",
    ["water.catcher"] = "media/ui/Facilities/Components/default.png",
}

function Definitions.GetComponentIconPath(role)
    return Definitions.ComponentIconPaths[tostring(role or "")]
        or "media/ui/Facilities/Components/default.png"
end

function Definitions.Register(definition)
    if type(definition) ~= "table" or type(definition.id) ~= "string"
        or definition.id == "" or type(definition.levels) ~= "table"
    then
        return false, "INVALID_FACILITY_DEFINITION"
    end
    Definitions.ByID[definition.id] = definition
    return true, definition
end

function Definitions.Get(id)
    return Definitions.ByID[tostring(id or "")]
end

function Definitions.GetLevel(id, level)
    local definition = Definitions.Get(id)
    return definition and definition.levels[math.floor(tonumber(level) or 1)] or nil
end

function Definitions.GetComponentLimit(id, level, role)
    local levelData = Definitions.GetLevel(id, level)
    local limit = levelData and levelData.componentLimits
        and levelData.componentLimits[tostring(role or "")] or nil
    if not limit then return nil end
    -- Anchors occupy one selected tile unless a definition explicitly models a
    -- multi-tile world object (beds are the first such special case).
    if limit.kind == "anchor" and limit.fixedTileCount == nil then
        limit.fixedTileCount = 1
    end
    return limit
end

Definitions.Register({
    id = "barracks",
    category = "housing",
    displayNameKey = "UI_PNC_Facility_Barracks",
    descriptionKey = "UI_PNC_Facility_BarracksDescription",
    iconPath = "media/ui/Facilities/BuildingMenu/livingRoom.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    buildWork = 80,
    reconstructWork = 50,
    deconstructWork = 50,
    allowMultipleRegions = true,
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "sleep", "rest" },
            componentLimits = {
                ["sleep.area"] = { kind = "region", minCount = 1 },
                ["sleep.bed"] = { kind = "anchor", minCount = 1, maxCount = 4,
                    fixedTileCount = 2, usesWorldObjectFootprint = true },
            },
            activityLimits = { sleep = { maxConcurrent = 4 } },
        },
        [2] = {
            requiredHQLevel = 2,
            capabilities = { "sleep", "rest" },
            componentLimits = {
                ["sleep.area"] = { kind = "region", minCount = 1 },
                ["sleep.bed"] = { kind = "anchor", minCount = 1, maxCount = 8,
                    fixedTileCount = 2, usesWorldObjectFootprint = true },
            },
            activityLimits = { sleep = { maxConcurrent = 8 } },
        },
        [3] = {
            requiredHQLevel = 3,
            capabilities = { "sleep", "rest" },
            componentLimits = {
                ["sleep.area"] = { kind = "region", minCount = 1 },
                ["sleep.bed"] = { kind = "anchor", minCount = 1, maxCount = 14,
                    fixedTileCount = 2, usesWorldObjectFootprint = true },
            },
            activityLimits = { sleep = { maxConcurrent = 14 } },
        },
    },
})

Definitions.Register({
    id = "farm",
    category = "food",
    displayNameKey = "UI_PNC_Facility_Farm",
    descriptionKey = "UI_PNC_Facility_FarmDescription",
    iconPath = "media/ui/Facilities/PNC_Farm_Placeholder.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    buildWork = 100,
    reconstructWork = 65,
    deconstructWork = 60,
    allowMultipleRegions = false,
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "farm.work" },
            componentLimits = {
                ["farm.field"] = { kind = "region", minCount = 1,
                    maxCount = 1, maxTotalTiles = 100, overlap = "exclusive",
                    worldRule = "farmland" },
            },
            activityLimits = { ["farm.work"] = { maxConcurrent = 2 } },
        },
        [2] = {
            requiredHQLevel = 2,
            capabilities = { "farm.work" },
            componentLimits = {
                ["farm.field"] = { kind = "region", minCount = 1,
                    maxCount = 1, maxTotalTiles = 180, overlap = "exclusive",
                    worldRule = "farmland" },
            },
            activityLimits = { ["farm.work"] = { maxConcurrent = 4 } },
        },
    },
})

Definitions.Register({
    id = "research_facility",
    category = "technology",
    displayNameKey = "UI_PNC_Facility_Research",
    descriptionKey = "UI_PNC_Facility_ResearchDescription",
    iconPath = "media/ui/Facilities/BuildingMenu/researchCenter.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    buildWork = 120,
    reconstructWork = 75,
    deconstructWork = 70,
    allowMultipleRegions = false,
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "work.research", "work.blueprint",
                "work.reverse" },
            componentLimits = {
                ["work.research"] = { kind = "anchor", minCount = 1,
                    maxCount = 1 },
                ["work.blueprint"] = { kind = "anchor", minCount = 1,
                    maxCount = 1 },
                ["work.reverse"] = { kind = "anchor", minCount = 1,
                    maxCount = 1 },
            },
            activityLimits = {
                ["work.research"] = { maxConcurrent = 1 },
                ["work.blueprint"] = { maxConcurrent = 1 },
                ["work.reverse"] = { maxConcurrent = 1 },
            },
            workstations = {
                research = { operation = "RESEARCH", capacity = 1,
                    role = "work.research", interactionAnchor = "research" },
                architect = { operation = "RESEARCH", capacity = 1,
                    role = "work.blueprint", interactionAnchor = "architect" },
                laboratory = { operation = "RESEARCH", capacity = 1,
                    role = "work.reverse", interactionAnchor = "laboratory" },
            },
        },
    },
})

Definitions.Register({
    id = "workshop",
    category = "production",
    displayNameKey = "UI_PNC_Facility_Workshop",
    descriptionKey = "UI_PNC_Facility_WorkshopDescription",
    iconPath = "media/ui/Facilities/BuildingMenu/workshop.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    buildWork = 140,
    reconstructWork = 90,
    deconstructWork = 80,
    requiredTechnology = "facility:workshop",
    allowMultipleRegions = false,
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "work.craft", "work.disassemble" },
            componentLimits = {
                ["work.craft"] = { kind = "anchor", minCount = 1, maxCount = 1 },
                ["work.disassemble"] = { kind = "anchor", minCount = 1,
                    maxCount = 1 },
            },
            activityLimits = {
                ["work.craft"] = { maxConcurrent = 1 },
                ["work.disassemble"] = { maxConcurrent = 1 },
            },
            workstations = {
                craft = { operation = "CRAFT", capacity = 1,
                    role = "work.craft", interactionAnchor = "craft" },
                disassemble = { operation = "DISASSEMBLE", capacity = 1,
                    role = "work.disassemble", interactionAnchor = "disassemble" },
            },
        },
    },
})

local waterLevels = {}
for level = 1, 10 do
    waterLevels[level] = {
        requiredHQLevel = math.min(3, math.ceil(level / 4)),
        requiredTechnology = "utility:water_collector:" .. tostring(level),
        capabilities = { "utility.water" },
        componentLimits = {
            ["water.spigot"] = { kind = "anchor", minCount = 1,
                maxCount = 1 },
            ["water.tank"] = { kind = "abstract", minCount = 0,
                maxCount = level * 4 },
            ["water.catcher"] = { kind = "abstract", minCount = 0,
                maxCount = level * 4 },
        },
        activityLimits = { ["utility.water"] = { maxConcurrent = 1 } },
    }
end

Definitions.Register({
    id = "water_collector",
    category = "utilities",
    displayNameKey = "UI_PNC_Facility_WaterCollector",
    descriptionKey = "UI_PNC_Facility_WaterCollectorDescription",
    iconPath = "media/ui/Facilities/BuildingMenu/waterStation.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    buildWork = 100,
    reconstructWork = 45,
    deconstructWork = 65,
    requiredTechnology = "utility:water_collector:1",
    allowMultipleRegions = false,
    levels = waterLevels,
})

return Definitions
