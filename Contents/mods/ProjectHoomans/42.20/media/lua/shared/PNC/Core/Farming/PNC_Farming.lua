PNC = PNC or {}
PNC.Farming = PNC.Farming or {}

local Farming = PNC.Farming
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

Farming.SCHEMA_VERSION = 1
Farming.FACILITY_ID = "farm"
Farming.FACILITY_TYPE = "FARM"
Farming.PLOT_ROLE = "growing.plot"
Farming.PLOT_TYPE = "GROWING_PLOT"
Farming.MAX_PLOT_WIDTH = 4
Farming.MAX_PLOT_HEIGHT = 4
Farming.MAX_PLOT_TILES = 16
Farming.MAX_ZONE_WIDTH = 20
Farming.MAX_ZONE_HEIGHT = 20
Farming.MAX_ZONE_TILES = 256
Farming.FARMER_JOB = "Farmer"

Farming.DEFAULT_POLICY = Farming.DEFAULT_POLICY or {
    autoPlow = true,
    autoPlant = true,
    autoWater = true,
    autoHarvest = true,
    autoReplant = true,
}

local function bool(value, fallback)
    if value == nil then return fallback == true end
    return value == true
end

function Farming.NormalizePolicy(value)
    value = type(value) == "table" and value or {}
    return {
        autoPlow = bool(value.autoPlow, Farming.DEFAULT_POLICY.autoPlow),
        autoPlant = bool(value.autoPlant, Farming.DEFAULT_POLICY.autoPlant),
        autoWater = bool(value.autoWater, Farming.DEFAULT_POLICY.autoWater),
        autoHarvest = bool(value.autoHarvest, Farming.DEFAULT_POLICY.autoHarvest),
        autoReplant = bool(value.autoReplant, Farming.DEFAULT_POLICY.autoReplant),
    }
end

function Farming.NormalizeCrop(value)
    value = tostring(value or "")
    if value == "" then return nil end
    return string.lower(value)
end

function Farming.RectangleInfo(region, limits)
    local ok, reason, normalized = GridRegion.validate(region)
    if not ok then return false, reason end
    local bounds = GridRegion.bounds(normalized)
    if not bounds or bounds.minZ ~= bounds.maxZ then
        return false, "GROWING_PLOT_ONE_LEVEL"
    end
    local maxWidth = tonumber(limits and limits.maxWidth) or Farming.MAX_PLOT_WIDTH
    local maxHeight = tonumber(limits and limits.maxHeight) or Farming.MAX_PLOT_HEIGHT
    local maxTiles = tonumber(limits and limits.maxTiles) or Farming.MAX_PLOT_TILES
    local width = bounds.maxX - bounds.minX + 1
    local height = bounds.maxY - bounds.minY + 1
    if width < 1 or height < 1 then return false, "GROWING_PLOT_EMPTY" end
    if width > maxWidth then
        return false, "GROWING_PLOT_WIDTH_LIMIT"
    end
    if height > maxHeight then
        return false, "GROWING_PLOT_HEIGHT_LIMIT"
    end
    if width * height > maxTiles then
        return false, "GROWING_PLOT_TILE_LIMIT"
    end
    local level = normalized.levels[bounds.minZ]
    for y = bounds.minY, bounds.maxY do
        local spans = level and level.rows and level.rows[y] or nil
        if not spans or #spans ~= 2
            or spans[1] ~= bounds.minX or spans[2] ~= bounds.maxX
        then
            return false, "GROWING_PLOT_RECTANGLE_REQUIRED"
        end
    end
    if GridRegion.countTiles(normalized) ~= width * height then
        return false, "GROWING_PLOT_RECTANGLE_REQUIRED"
    end
    return true, nil, {
        region = normalized,
        minX = bounds.minX, maxX = bounds.maxX,
        minY = bounds.minY, maxY = bounds.maxY,
        z = bounds.minZ, width = width, height = height,
        tileCount = width * height,
    }
end

---Validates a larger RimWorld-style farming zone geometry or bounds rectangle.
function Farming.ZoneInfo(zone)
    local region = zone and (zone.geometry or zone.region) or nil
    if region then
        return Farming.RectangleInfo(region, {
            maxWidth = Farming.MAX_ZONE_WIDTH,
            maxHeight = Farming.MAX_ZONE_HEIGHT,
            maxTiles = Farming.MAX_ZONE_TILES,
        })
    end
    local b = zone and (zone.bounds or (zone.minX ~= nil and zone or nil)) or nil
    if not b then return false, "FARM_ZONE_REGION_REQUIRED" end
    local minX, maxX = math.floor(tonumber(b.minX) or 0), math.floor(tonumber(b.maxX) or -1)
    local minY, maxY = math.floor(tonumber(b.minY) or 0), math.floor(tonumber(b.maxY) or -1)
    local z = math.floor(tonumber(b.minZ or zone.z or b.z) or 0)
    local built = GridRegion.fromRectangle and GridRegion.fromRectangle(minX, minY, maxX, maxY, z) or nil
    if not built then
        local width, height = maxX - minX + 1, maxY - minY + 1
        if width < 1 or height < 1 then return false, "FARM_ZONE_EMPTY" end
        if width * height > Farming.MAX_ZONE_TILES then return false, "FARM_ZONE_TILE_LIMIT" end
        return true, nil, {
            minX = minX, maxX = maxX, minY = minY, maxY = maxY,
            z = z, width = width, height = height, tileCount = width * height,
        }
    end
    return Farming.RectangleInfo(built, {
        maxWidth = Farming.MAX_ZONE_WIDTH,
        maxHeight = Farming.MAX_ZONE_HEIGHT,
        maxTiles = Farming.MAX_ZONE_TILES,
    })
end

function Farming.NormalizePlotState(input)
    input = type(input) == "table" and input or {}
    return {
        schemaVersion = Farming.SCHEMA_VERSION,
        logicalType = Farming.PLOT_TYPE,
        desiredCrop = Farming.NormalizeCrop(input.desiredCrop),
        policy = Farming.NormalizePolicy(input.policy),
    }
end

return Farming
