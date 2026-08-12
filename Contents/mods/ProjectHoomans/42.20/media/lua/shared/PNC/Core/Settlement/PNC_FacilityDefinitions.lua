PNC = PNC or {}
PNC.FacilityDefinitions = PNC.FacilityDefinitions or {}

local Definitions = PNC.FacilityDefinitions
Definitions.SCHEMA_VERSION = 1
Definitions.ByID = Definitions.ByID or {}

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

Definitions.Register({
    id = "barracks",
    displayNameKey = "UI_PNC_Facility_Barracks",
    descriptionKey = "UI_PNC_Facility_BarracksDescription",
    iconPath = "media/ui/Facilities/PNC_Barracks_Placeholder.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    allowMultipleRegions = true,
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "sleep", "rest" },
            componentLimits = {
                ["sleep.area"] = { kind = "region", minCount = 1 },
                ["sleep.bed"] = { kind = "anchor", minCount = 1, maxCount = 4 },
            },
            activityLimits = { sleep = { maxConcurrent = 4 } },
        },
        [2] = {
            requiredHQLevel = 2,
            capabilities = { "sleep", "rest" },
            componentLimits = {
                ["sleep.area"] = { kind = "region", minCount = 1 },
                ["sleep.bed"] = { kind = "anchor", minCount = 1, maxCount = 8 },
            },
            activityLimits = { sleep = { maxConcurrent = 8 } },
        },
        [3] = {
            requiredHQLevel = 3,
            capabilities = { "sleep", "rest" },
            componentLimits = {
                ["sleep.area"] = { kind = "region", minCount = 1 },
                ["sleep.bed"] = { kind = "anchor", minCount = 1, maxCount = 14 },
            },
            activityLimits = { sleep = { maxConcurrent = 14 } },
        },
    },
})

Definitions.Register({
    id = "farm",
    displayNameKey = "UI_PNC_Facility_Farm",
    descriptionKey = "UI_PNC_Facility_FarmDescription",
    iconPath = "media/ui/Facilities/PNC_Farm_Placeholder.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
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

return Definitions
