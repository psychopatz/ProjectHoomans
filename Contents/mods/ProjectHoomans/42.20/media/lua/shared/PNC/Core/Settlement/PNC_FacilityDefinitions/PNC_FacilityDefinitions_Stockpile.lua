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
    -- The world visual is deliberately separate from the storage/work area.
    -- Future rotatable visuals can provide four entries in `sprites`; the
    -- first stockpile pass uses one non-rotatable object per storage tier.
    visual = {
        mode = "nonrotatable",
        tiers = {
            [1] = { sprite = "trash_01_22" },
            [2] = { sprite = "trash_01_47" },
            [3] = { sprite = "trash_01_44" },
            [4] = { sprite = "trash_01_40" },
            [5] = { sprite = "trash_01_41" },
            -- Captured from the primary [Debug] Grab Object Name entries.
            -- These furniture sprites are thumpables so their world object
            -- type matches the objects selected in-game.
            [6] = { sprite = "furniture_storage_01_53",
                objectType = "thumpable" }, -- Table
            [7] = { sprite = "furniture_storage_02_29",
                objectType = "thumpable" }, -- Chest
            [8] = { sprite = "furniture_storage_01_49",
                objectType = "thumpable" }, -- Drawers
            [9] = { sprite = "furniture_storage_01_46",
                objectType = "thumpable" }, -- Drawers
            [10] = { sprite = "furniture_storage_01_32",
                objectType = "thumpable" }, -- Drawers
            [11] = { sprite = "furniture_storage_01_12",
                objectType = "thumpable" }, -- Drawers
            [12] = { sprite = "furniture_storage_01_8",
                objectType = "thumpable" }, -- Drawers
            [13] = { sprite = "furniture_storage_01_42",
                objectType = "thumpable" }, -- Drawers
            [14] = { sprite = "furniture_storage_02_16",
                objectType = "thumpable" }, -- Cartbox
            [15] = { sprite = "furniture_storage_02_9",
                objectType = "thumpable" }, -- Locker
            [16] = { sprite = "furniture_storage_02_1",
                objectType = "thumpable" }, -- Locker
            [17] = { sprite = "furniture_storage_02_4",
                objectType = "thumpable" }, -- Locker
            [18] = { sprite = "furniture_storage_02_12",
                objectType = "thumpable" }, -- Locker
        },
    },
    levels = stockpileLevels,
})

return Definitions
