local Definitions = PNC.FacilityDefinitions
    or require "PNC/Core/Settlement/PNC_FacilityDefinitions/PNC_FacilityDefinitions_Core"

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
    componentCosts = {
        ["sleep.bed"] = {{ fullType = "Base.Money", amount = 1 }},
    },
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "sleep", "rest" },
            componentLimits = {
                ["sleep.bed"] = { kind = "anchor", minCount = 1, maxCount = 4,
                    fixedTileCount = 2, usesWorldObjectFootprint = true },
            },
            activityLimits = { sleep = { maxConcurrent = 4 } },
        },
        [2] = {
            requiredHQLevel = 2,
            capabilities = { "sleep", "rest" },
            componentLimits = {
                ["sleep.bed"] = { kind = "anchor", minCount = 1, maxCount = 8,
                    fixedTileCount = 2, usesWorldObjectFootprint = true },
            },
            activityLimits = { sleep = { maxConcurrent = 8 } },
        },
        [3] = {
            requiredHQLevel = 3,
            capabilities = { "sleep", "rest" },
            componentLimits = {
                ["sleep.bed"] = { kind = "anchor", minCount = 1, maxCount = 14,
                    fixedTileCount = 2, usesWorldObjectFootprint = true },
            },
            activityLimits = { sleep = { maxConcurrent = 14 } },
        },
    },
})

return Definitions
