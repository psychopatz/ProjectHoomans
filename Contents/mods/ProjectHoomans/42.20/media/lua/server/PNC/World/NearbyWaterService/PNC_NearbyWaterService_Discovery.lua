if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NearbyWaterService = PNC.NearbyWaterService or {}
PNC.NearbyWaterServiceInternal =
    PNC.NearbyWaterServiceInternal or {}

local Service = PNC.NearbyWaterService
local H = PNC.NearbyWaterServiceInternal
local Locator = PNC.NearbyResourceLocator
local RADIUS = 12
local MAX_DRINK_LITERS = 1
local APPROACH_OFFSETS = {
    { x = 0, y = 1 }, { x = 0, y = -1 },
    { x = 1, y = 0 }, { x = -1, y = 0 },
    { x = 1, y = 1 }, { x = -1, y = 1 },
    { x = 1, y = -1 }, { x = -1, y = -1 },
}

function H.SourceEntry(object, square, ordinal)
    if not object or not square or not Service.IsCleanFaucet(object) then
        return nil
    end
    local x, y, z = H.SquarePosition(square)
    if not x then return nil end
    return {
        kind = "faucet", object = object, square = square,
        x = x, y = y, z = z,
        key = Locator.ObjectKeyFor(object, x, y, z, ordinal),
    }
end

function H.FindInternal(record, key)
    local origin = H.OriginFor(record)
    if not origin then return nil end
    local itemEntry = Locator.Find(origin, {
        radius = RADIUS, cacheKey = "nearby_water:" .. tostring(record.id),
        accept = function(entry)
            return (not key or entry.key == key) and Service.IsCleanWater(
                entry.item)
        end,
    })
    local faucetEntry = Locator.FindObject(origin, {
        radius = RADIUS, cacheKey = "nearby_water:" .. tostring(record.id),
        accept = function(entry)
            return (not key or entry.key == key)
                and Service.IsCleanFaucet(entry.object)
        end,
    })
    if faucetEntry then
        faucetEntry.kind = "faucet"
        faucetEntry.key = faucetEntry.key or Locator.ObjectKeyFor(
            faucetEntry.object, faucetEntry.x, faucetEntry.y, faucetEntry.z)
    end
    if not itemEntry then return faucetEntry end
    if not faucetEntry or itemEntry.distSq <= faucetEntry.distSq then
        itemEntry.kind = "container"
        return itemEntry
    end
    return faucetEntry
end

function Service.Find(record)
    return H.FindInternal(record)
end

function Service.Resolve(record, key)
    return H.FindInternal(record, tostring(key or ""))
end

function Service.FindAt(record, x, y, z)
    local origin = H.OriginFor(record)
    if not origin then return nil end
    x, y, z = math.floor(tonumber(x) or 0), math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    local cell = getCell and getCell() or nil
    local square = cell and cell.getGridSquare
        and cell:getGridSquare(x, y, z) or nil
    local objects = square and H.Call(square, "getObjects") or nil
    for index = 0, H.ListSize(objects) - 1 do
        local entry = H.SourceEntry(H.ListItem(objects, index), square, index)
        if entry then return entry end
    end
    return nil
end

return Service

