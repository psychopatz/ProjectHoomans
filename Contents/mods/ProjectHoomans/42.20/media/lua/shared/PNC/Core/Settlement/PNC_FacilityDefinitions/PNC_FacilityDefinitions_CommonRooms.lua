local Definitions = PNC.FacilityDefinitions
    or require "PNC/Core/Settlement/PNC_FacilityDefinitions/PNC_FacilityDefinitions_Core"

Definitions.Register({
    id = "living_room",
    category = "housing",
    displayNameKey = "UI_PNC_Facility_LivingRoom",
    descriptionKey = "UI_PNC_Facility_LivingRoomDescription",
    iconPath = "media/ui/Facilities/BuildingMenu/livingRoom.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    componentCosts = {
        ["living.room"] = {{ fullType = "Base.Money", amount = 1 }},
        ["living.chair"] = {{ fullType = "Base.Money", amount = 1 }},
    },
    componentWork = { ["living.room"] = 40, ["living.chair"] = 40 },
    buildWork = 100,
    reconstructWork = 65,
    deconstructWork = 60,
    allowMultipleRegions = false,
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "living", "recreation" },
            componentLimits = {
                ["living.room"] = { kind = "region", minCount = 1,
                    maxCount = 1, minTotalTiles = 1, maxTotalTiles = 1000,
                    roomGroup = "living" },
                ["living.chair"] = { kind = "anchor", minCount = 1,
                    maxCount = 8, roomGroup = "living" },
            },
            activityLimits = { living = { maxConcurrent = 8 },
                recreation = { maxConcurrent = 8 } },
        },
    },
})

Definitions.Register({
    id = "dining_room",
    category = "food",
    displayNameKey = "UI_PNC_Facility_DiningRoom",
    descriptionKey = "UI_PNC_Facility_DiningRoomDescription",
    iconPath = "media/ui/Facilities/BuildingMenu/diningRoom.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    componentCosts = {
        ["dining.table"] = {{ fullType = "Base.Money", amount = 1 }},
    },
    buildWork = 90,
    reconstructWork = 55,
    deconstructWork = 50,
    allowMultipleRegions = false,
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "food.dine" },
            componentLimits = {
                ["dining.table"] = { kind = "anchor", minCount = 1,
                    maxCount = 6 },
            },
            activityLimits = { ["food.dine"] = { maxConcurrent = 6 } },
        },
    },
})

Definitions.Register({
    id = "hospital",
    category = "housing",
    displayNameKey = "UI_PNC_Facility_Hospital",
    descriptionKey = "UI_PNC_Facility_HospitalDescription",
    iconPath = "media/ui/Facilities/BuildingMenu/hospital.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    componentCosts = {
        ["health.bed"] = {{ fullType = "Base.Money", amount = 1 }},
    },
    buildWork = 120,
    reconstructWork = 75,
    deconstructWork = 65,
    allowMultipleRegions = false,
    levels = {
        [1] = {
            requiredHQLevel = 1,
            capabilities = { "health.recover" },
            componentLimits = {
                ["health.bed"] = { kind = "anchor", minCount = 1,
                    maxCount = 4 },
            },
            activityLimits = { ["health.recover"] = { maxConcurrent = 4 } },
        },
    },
})

return Definitions
