local Definitions = PNC.FacilityDefinitions
    or require "PNC/Core/Settlement/PNC_FacilityDefinitions/PNC_FacilityDefinitions_Core"

Definitions.Register({
    id = "farm",
    logicalType = "FARM",
    category = "food",
    displayNameKey = "UI_PNC_Facility_Farm",
    descriptionKey = "UI_PNC_Facility_FarmDescription",
    iconPath = "media/ui/Facilities/PNC_Farm_Placeholder.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    buildWork = 100,
    reconstructWork = 65,
    deconstructWork = 60,
    -- Farming uses an editable labor standing area; room and workstation
    -- facilities do not receive one implicitly.
    requiresWorkZone = true,
    allowMultipleRegions = false,
    componentConstruction = { ["growing.plot"] = false },
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "farm.work" },
            componentLimits = {
                ["growing.plot"] = { kind = "region", minCount = 0,
                    maxCount = 2, maxTotalTiles = 32, overlap = "exclusive",
                    worldRule = "farming_furrow", maxWidth = 4,
                    maxHeight = 4, rectangular = true },
            },
            activityLimits = { ["farm.work"] = { maxConcurrent = 2 } },
        },
        [2] = {
            requiredHQLevel = 2,
            capabilities = { "farm.work" },
            componentLimits = {
                ["growing.plot"] = { kind = "region", minCount = 0,
                    maxCount = 4, maxTotalTiles = 64, overlap = "exclusive",
                    worldRule = "farming_furrow", maxWidth = 4,
                    maxHeight = 4, rectangular = true },
            },
            activityLimits = { ["farm.work"] = { maxConcurrent = 4 } },
        },
    },
})

return Definitions
