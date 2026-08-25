local Definitions = PNC.FacilityDefinitions
    or require "PNC/Core/Settlement/PNC_FacilityDefinitions/PNC_FacilityDefinitions_Core"
local WorkDefinitions = PNC.WorkDefinitions
    or require "PNC/Core/Production/WorkDefinition/PNC_WorkDefinitions"

Definitions.Register({
    id = "research_facility",
    category = "technology",
    displayNameKey = "UI_PNC_Facility_Research",
    descriptionKey = "UI_PNC_Facility_ResearchDescription",
    -- Research is a native Build 42 workstation now. The build menu uses
    -- the Log Table recipe's native name, materials, and icon.
    iconPath = nil,
    buildRecipeObjectInfoName = "Base.Log_Table",
    entityScript = "Base.Log_Table",
    directWorkstation = true,
    stationId = "research_facility",
    workstationRole = "work.research",
    buildCosts = {},
    buildWork = 120,
    reconstructWork = 75,
    deconstructWork = 70,
    allowMultipleRegions = true,
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "work.research", "work.blueprint",
                "work.reverse" },
            componentLimits = {
                ["work.research"] = { kind = "anchor", minCount = 1,
                    maxCount = 1, managed = true },
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
                    role = "work.research", interactionAnchor = "research" },
                laboratory = { operation = "RESEARCH", capacity = 1,
                    role = "work.research", interactionAnchor = "research" },
            },
        },
    },
})

Definitions.Register({
    id = "workshop",
    -- Kept as a compatibility definition for existing settlements and for
    -- recipes whose vanilla tag has no dedicated station mapping. New
    -- crafting stations are direct workstation facilities below.
    legacyOnly = true,
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
            capabilities = { "work.craft" },
            componentLimits = {
                ["work.craft"] = { kind = "anchor", minCount = 1,
                    maxCount = 1 },
                -- Retained for old saved workshop rows. Crafting and
                -- salvaging now reserve the same physical craft anchor;
                -- this legacy row is no longer required for new builds.
                ["work.disassemble"] = { kind = "anchor", minCount = 1,
                    maxCount = 1 },
            },
            activityLimits = {
                ["work.craft"] = { maxConcurrent = 1 },
            },
            workstations = {
                craft = { operation = "CRAFT", capacity = 1,
                    role = "work.craft", interactionAnchor = "craft" },
                disassemble = { operation = "DISASSEMBLE", capacity = 1,
                    role = "work.craft", interactionAnchor = "craft" },
            },
        },
    },
})

local function registerDirectWorkstation(station)
    local id = tostring(station.id or "")
    if id == "" or not station.entityScript then return end
    Definitions.Register({
        id = id,
        category = station.productionSkillId or "production",
        displayNameKey = station.labelKey,
        descriptionKey = "UI_PNC_Facility_WorkstationDescription",
        -- Native Build 42 recipe metadata is the source of truth for the
        -- icon, display name, materials, and build work. Keep only the
        -- object identity here so definitions remain serializable.
        buildRecipeObjectInfoName = station.buildRecipeObjectInfoName
            or station.entityScript,
        iconPath = nil,
        buildCosts = {},
        -- Kept for compatibility with already-planned legacy facility
        -- orders; native object builds use the catalog's buildWork.
        buildWork = 140,
        reconstructWork = 90,
        deconstructWork = 80,
        requiredTechnology = station.requiredTechnology,
        allowMultipleRegions = true,
        directWorkstation = true,
        stationId = id,
        entityScript = station.entityScript,
        specializationSkills = station.specializationSkills,
        productionSkillId = station.productionSkillId,
        workstationRole = "work.craft",
        levels = {
            [1] = {
                requiredHQLevel = 1,
                capabilities = { "work.craft" },
                componentLimits = {
                    ["work.craft"] = { kind = "anchor", minCount = 1,
                        maxCount = 1, managed = true },
                },
                activityLimits = {
                    ["work.craft"] = { maxConcurrent = 1 },
                },
                workstations = {
                    craft = { operation = "CRAFT", capacity = 1,
                        role = "work.craft", interactionAnchor = "craft" },
                    disassemble = { operation = "DISASSEMBLE", capacity = 1,
                        role = "work.craft", interactionAnchor = "craft" },
                },
            },
        },
    })
end

for _, station in pairs(WorkDefinitions.STATIONS or {}) do
    if station.directWorkstation == true then
        registerDirectWorkstation(station)
    end
end

return Definitions
