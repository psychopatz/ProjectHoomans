-- Shared native-building footprint helpers.
--
-- The vanilla ISBuildIsoEntity cursor validates every occupied face tile.
-- Project Hoomans uses the same face data for the base-territory rule so the
-- client preview and the server completion check agree for multi-tile objects.

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Footprint = {}

local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function faceIndex(nSprite)
    nSprite = tonumber(nSprite) or 1
    if nSprite == 2 then return 0 end
    if nSprite == 4 then return 2 end
    return nSprite
end

local function addTile(levels, x, y, z)
    levels[z] = levels[z] or { rows = {} }
    local row = levels[z].rows[y] or {}
    row[#row + 1], row[#row + 2] = x, x
    levels[z].rows[y] = row
end

function Footprint.FaceForObjectInfo(objectInfo, nSprite)
    return call(objectInfo, "getFace", faceIndex(nSprite))
end

function Footprint.Anchor(x, y, z)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return nil end
    return GridRegion.normalize({ levels = {
        [math.floor(z)] = { rows = {
            [math.floor(y)] = { math.floor(x), math.floor(x) },
        } },
    } })
end

function Footprint.FromFace(face, x, y, z)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not face or not x or not y or not z then return nil end

    local levels = {}
    local layerCount = tonumber(call(face, "getzLayers")) or 0
    local width = tonumber(call(face, "getWidth")) or 0
    local height = tonumber(call(face, "getHeight")) or 0
    local tileCount = 0
    for zz = 0, layerCount - 1 do
        for xx = 0, width - 1 do
            for yy = 0, height - 1 do
                local tile = call(face, "getTileInfo", xx, yy, zz)
                local spriteName = call(tile, "getSpriteName")
                local blocking = call(tile, "isBlocking")
                if tile and (spriteName or blocking == true) then
                    addTile(levels, math.floor(x) + xx, math.floor(y) + yy,
                        math.floor(z) + zz)
                    tileCount = tileCount + 1
                end
            end
        end
    end

    -- Keep malformed/partial object metadata safe. Vanilla still validates
    -- the anchor in this case, so the project boundary rule must do the same.
    if tileCount == 0 then
        addTile(levels, math.floor(x), math.floor(y), math.floor(z))
    end
    return GridRegion.normalize({ levels = levels })
end

function Footprint.FromObjectInfo(objectInfo, nSprite, x, y, z)
    return Footprint.FromFace(
        Footprint.FaceForObjectInfo(objectInfo, nSprite), x, y, z)
        or Footprint.Anchor(x, y, z)
end

function Footprint.FromCursor(cursor, square)
    if not cursor or not square then return nil end
    local x = call(square, "getX")
    local y = call(square, "getY")
    local z = call(square, "getZ")
    local face = call(cursor, "getFace")
    return Footprint.FromFace(face, x, y, z) or Footprint.Anchor(x, y, z)
end

function Footprint.ForEachTile(region, callback)
    if type(callback) ~= "function" then return false end
    region = GridRegion.normalize(region)
    for z, level in pairs(region.levels or {}) do
        for y, spans in pairs(level.rows or {}) do
            for index = 1, #spans, 2 do
                for x = spans[index], spans[index + 1] do
                    if callback(x, y, z) == false then return false end
                end
            end
        end
    end
    return true
end

function Footprint.AllInside(region, contains)
    if type(contains) ~= "function" then return false end
    local valid = true
    Footprint.ForEachTile(region, function(x, y, z)
        if contains(x, y, z) ~= true then
            valid = false
            return false
        end
        return true
    end)
    return valid
end

return Footprint
