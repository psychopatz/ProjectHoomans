local Definitions = PNC.FacilityDefinitions
    or require "PNC/Core/Settlement/PNC_FacilityDefinitions/PNC_FacilityDefinitions_Core"

local waterLevels = {}
for level = 1, 10 do
    waterLevels[level] = {
        requiredHQLevel = math.min(3, math.ceil(level / 4)),
        requiredTechnology = "utility:water_collector:" .. tostring(level),
        capabilities = { "utility.water", "water.drink" },
        componentLimits = {
            ["water.spigot"] = { kind = "anchor", minCount = 1,
                maxCount = 1 },
            ["water.tank"] = { kind = "abstract", minCount = 0,
                maxCount = level * 4 },
            ["water.catcher"] = { kind = "abstract", minCount = 0,
                maxCount = level * 4 },
        },
        activityLimits = {
            ["utility.water"] = { maxConcurrent = 1 },
            ["water.drink"] = { maxConcurrent = 1 },
        },
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
