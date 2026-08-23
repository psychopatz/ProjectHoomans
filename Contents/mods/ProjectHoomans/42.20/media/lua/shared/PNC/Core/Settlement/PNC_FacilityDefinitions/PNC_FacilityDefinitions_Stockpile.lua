local Definitions = PNC.FacilityDefinitions
    or require "PNC/Core/Settlement/PNC_FacilityDefinitions/PNC_FacilityDefinitions_Core"

local stockpileLevels = {}
for level = 1, 10 do
    stockpileLevels[level] = {
        requiredHQLevel = math.min(3, math.ceil(level / 4)),
        requiredTechnology = level > 1 and "storage:" .. tostring(level) or nil,
        capabilities = { "storage.stockpile" },
        componentLimits = {
            ["storage.stockpile"] = { kind = "region", minCount = 1,
                maxCount = 1, minTotalTiles = 1, maxTotalTiles = 1000 },
        },
        activityLimits = { ["storage.stockpile"] = { maxConcurrent = 1 } },
    }
end

Definitions.Register({
    id = "stockpile",
    category = "production",
    displayNameKey = "UI_PNC_Facility_Stockpile",
    descriptionKey = "UI_PNC_Facility_StockpileDescription",
    iconPath = "media/ui/Facilities/Components/storage/stockpile.png",
    buildCosts = {{ fullType = "Base.Money", amount = 1 }},
    upgradeCosts = {{ fullType = "Base.Money", amount = 1 }},
    componentCosts = {
        ["storage.stockpile"] = {{ fullType = "Base.Money", amount = 1 }},
    },
    buildWork = 60,
    reconstructWork = 45,
    deconstructWork = 45,
    singleton = true,
    bootstrapFromPlayer = true,
    providesStockpileAccess = true,
    allowMultipleRegions = false,
    levels = stockpileLevels,
})

return Definitions
