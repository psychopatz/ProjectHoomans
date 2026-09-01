-- Tile classification and shoreline spot derivation for fishing zones.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.FishingService
local H = Service.Internal

local OFFSETS = {
    { x = -1, y = 0, facing = "E" }, { x = 1, y = 0, facing = "W" },
    { x = 0, y = -1, facing = "S" }, { x = 0, y = 1, facing = "N" },
    { x = -1, y = -1, facing = "SE" }, { x = 1, y = -1, facing = "SW" },
    { x = -1, y = 1, facing = "NE" }, { x = 1, y = 1, facing = "NW" },
}

local function getCell()
    if _G and type(_G.getCell) == "function" then
        local ok, cell = pcall(_G.getCell)
        if ok then return cell end
    end
    if IsoWorld and IsoWorld.instance then return IsoWorld.instance.currentCell end
    return nil
end

function Service.GetSquare(x, y, z)
    local cell = getCell()
    if not cell or type(cell.getGridSquare) ~= "function" then return nil end
    local ok, square = pcall(cell.getGridSquare, cell, x, y, z)
    return ok and square or nil
end

local function isWater(square)
    local properties
    local ok
    local result
    if not square then return false end
    if square.water == true then return true end
    if type(square.isWater) == "function" then
        ok, result = pcall(square.isWater, square)
        if ok and result == true then return true end
    end
    if type(square.getProperties) == "function" then
        ok, properties = pcall(square.getProperties, square)
        if ok and properties and type(properties.has) == "function"
            and IsoFlagType and IsoFlagType.water
        then
            ok, result = pcall(properties.has, properties, IsoFlagType.water)
            if ok and result == true then return true end
        end
    end
    return false
end

local function isWalkable(square)
    local ok
    local result
    if not square or isWater(square) then return false end
    if square.walkable == false or square.solid == true then return false end
    if type(square.isFree) == "function" then
        ok, result = pcall(square.isFree, square, true)
        if ok and result == false then return false end
    end
    return true
end

local function spotID(x, y, z)
    return tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

function H.DeriveFishingSpots(zone)
    local bounds = H.ZoneBounds(zone)
    local waters = {}
    local lands = {}
    local x, y, z
    local square
    zone.waterCount, zone.landCount, zone.unloadedTiles = 0, 0, 0
    if not bounds then return false, "fishing_zone_bounds_missing" end
    z = bounds.minZ
    for y = bounds.minY, bounds.maxY do
        for x = bounds.minX, bounds.maxX do
            if H.ZoneContains(zone, x, y, z) then
                square = Service.GetSquare(x, y, z)
                if not square then
                    zone.unloadedTiles = zone.unloadedTiles + 1
                elseif isWater(square) then
                    waters[spotID(x, y, z)] = true
                    zone.waterCount = zone.waterCount + 1
                else
                    zone.landCount = zone.landCount + 1
                    if isWalkable(square) then lands[#lands + 1] = { x=x, y=y, z=z } end
                end
            end
        end
    end
    zone.fishingSpots = {}
    for _, land in ipairs(lands) do
        for _, offset in ipairs(OFFSETS) do
            x, y, z = land.x + offset.x, land.y + offset.y, land.z
            if H.ZoneContains(zone, x, y, z) and waters[spotID(x, y, z)] then
                zone.fishingSpots[#zone.fishingSpots + 1] = {
                    id = spotID(land.x, land.y, land.z),
                    standX = land.x + 0.5, standY = land.y + 0.5,
                    standZ = land.z, waterX = x + 0.5, waterY = y + 0.5,
                    waterZ = z, facing = offset.facing,
                }
                break
            end
        end
    end
    table.sort(zone.fishingSpots, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    zone.valid = zone.waterCount > 0 and zone.landCount > 0
        and #zone.fishingSpots > 0
    if not zone.valid then
        return false, zone.waterCount <= 0 and "fishing_zone_no_water"
            or zone.landCount <= 0 and "fishing_zone_no_land"
            or "fishing_zone_no_shoreline"
    end
    return true
end

return Service
