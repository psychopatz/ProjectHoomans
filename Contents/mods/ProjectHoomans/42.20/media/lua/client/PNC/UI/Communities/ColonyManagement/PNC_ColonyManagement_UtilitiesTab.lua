local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Utilities = {}

local function row(key, label, detail, color)
    return { key = key, label = label, detail = detail, colorName = color }
end

function Utilities.BuildRows(context)
    local utility = context.snapshot and context.snapshot.utilities or {}
    local liters = tonumber(utility.waterLiters) or 0
    local capacity = tonumber(utility.capacityLiters) or 0
    local rows = {
        row("water", Shared.Tr("UI_PNC_Utilities_Water", "WATER RESERVES"),
            string.format("%.0f / %.0f L", liters, capacity),
            capacity > 0 and "accent" or "warning"),
        row("weather", Shared.Tr("UI_PNC_Utilities_Weather", "WEATHER"),
            utility.raining and "RAINING - COLLECTING WATER" or "DRY",
            utility.raining and "success" or "muted"),
        row("tanks", Shared.Tr("UI_PNC_Utilities_Tanks", "WATER TANKS"),
            tostring(utility.tanks or 0) .. "  |  25 L EACH"),
        row("catchers", Shared.Tr("UI_PNC_Utilities_Catchers", "RAIN CATCHERS"),
            tostring(utility.catchers or 0) .. "  |  "
                .. tostring(utility.litersPerTenMinutes or 0)
                .. " L / 10 IN-GAME MINUTES"),
    }
    for index, facility in ipairs(utility.facilities or {}) do
        rows[#rows + 1] = row("collector:" .. tostring(facility.facilityId),
            "WATER COLLECTOR #" .. tostring(index) .. "  |  LEVEL "
                .. tostring(facility.level or 1),
            string.format("%.0f / %.0f L  |  %d TANKS  |  %d CATCHERS",
                tonumber(facility.waterLiters) or 0,
                tonumber(facility.capacityLiters) or 0,
                tonumber(facility.tanks) or 0,
                tonumber(facility.catchers) or 0),
            facility.operational and "success" or "warning")
    end
    return rows
end

return Utilities
