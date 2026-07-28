--[[
    PNC Vehicle Avoidance
    Builds a short-lived, shared footprint cache from loaded BaseVehicles.
    This supplements IsoGridSquare:isVehicleIntersecting(), whose square cache
    can briefly lag behind vehicle synchronization in multiplayer.
]]

PNC = PNC or {}
PNC.VehicleAvoidance = PNC.VehicleAvoidance or {}

local Avoidance = PNC.VehicleAvoidance
local Const = PNC.Const or {}
local Core = PNC.Core
local cache = {
    cell = nil,
    builtAt = nil,
    exact = {},
    clearance = {},
}

local function nowMs()
    if Core and Core.Now then
        return tonumber(Core.Now()) or 0
    end
    if getTimestampMs then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

local function call(object, methodName, ...)
    local method
    local ok
    local result
    if not object then return nil end
    method = object[methodName]
    if type(method) ~= "function" then return nil end
    ok, result = pcall(method, object, ...)
    if not ok then return nil end
    return result
end

local function tileKey(x, y, z)
    return tostring(math.floor(tonumber(z) or 0))
        .. ":" .. tostring(math.floor(tonumber(x) or 0))
        .. ":" .. tostring(math.floor(tonumber(y) or 0))
end

local function visitVehicles(vehicles, visitor)
    local size
    local iterator
    local ok
    local hasNext
    local vehicle
    local i
    if not vehicles then return end
    if vehicles.size and vehicles.get then
        size = tonumber(call(vehicles, "size")) or 0
        for i = 0, size - 1 do
            vehicle = call(vehicles, "get", i)
            if vehicle then visitor(vehicle) end
        end
        return
    end
    iterator = call(vehicles, "iterator")
    if not iterator then return end
    while true do
        ok, hasNext = pcall(iterator.hasNext, iterator)
        if not ok or hasNext ~= true then break end
        vehicle = call(iterator, "next")
        if vehicle then visitor(vehicle) end
    end
end

local function markVehicle(vehicle, exact, clearance)
    local poly
    local z
    local minX
    local maxX
    local minY
    local maxY
    local x
    local y
    local dx
    local dy
    local radius = math.max(
        0,
        math.floor(tonumber(Const.VEHICLE_AVOIDANCE_CLEARANCE_TILES) or 1)
    )
    if call(vehicle, "isRemovedFromWorld") == true then return end
    poly = call(vehicle, "getPolyPlusRadius") or call(vehicle, "getPoly")
    if not poly then return end
    z = math.floor(tonumber(poly.z) or 0)
    minX = math.floor(math.min(
        tonumber(poly.x1) or 0,
        tonumber(poly.x2) or 0,
        tonumber(poly.x3) or 0,
        tonumber(poly.x4) or 0
    )) - 1
    maxX = math.floor(math.max(
        tonumber(poly.x1) or 0,
        tonumber(poly.x2) or 0,
        tonumber(poly.x3) or 0,
        tonumber(poly.x4) or 0
    )) + 1
    minY = math.floor(math.min(
        tonumber(poly.y1) or 0,
        tonumber(poly.y2) or 0,
        tonumber(poly.y3) or 0,
        tonumber(poly.y4) or 0
    )) - 1
    maxY = math.floor(math.max(
        tonumber(poly.y1) or 0,
        tonumber(poly.y2) or 0,
        tonumber(poly.y3) or 0,
        tonumber(poly.y4) or 0
    )) + 1
    for x = minX, maxX do
        for y = minY, maxY do
            if call(vehicle, "isIntersectingSquare", x, y, z) == true then
                exact[tileKey(x, y, z)] = true
                for dx = -radius, radius do
                    for dy = -radius, radius do
                        if dx ~= 0 or dy ~= 0 then
                            clearance[tileKey(x + dx, y + dy, z)] = true
                        end
                    end
                end
            end
        end
    end
end

local function rebuild(cell, now)
    local vehicles = call(cell, "getVehicles")
    local exact = {}
    local clearance = {}
    visitVehicles(vehicles, function(vehicle)
        markVehicle(vehicle, exact, clearance)
    end)
    cache.cell = cell
    cache.builtAt = now
    cache.exact = exact
    cache.clearance = clearance
end

local function ensure(cell)
    local now = nowMs()
    local interval = math.max(
        50,
        math.floor(tonumber(Const.VEHICLE_AVOIDANCE_CACHE_MS) or 250)
    )
    if cache.cell ~= cell
        or cache.builtAt == nil
        or now - cache.builtAt >= interval
    then
        rebuild(cell, now)
    end
end

function Avoidance.Invalidate()
    cache.cell = nil
    cache.builtAt = nil
    cache.exact = {}
    cache.clearance = {}
end

function Avoidance.GetReason(x, y, z, cell, includeClearance)
    local square
    local key
    cell = cell or (getCell and getCell() or nil)
    if not cell then return nil end
    square = call(
        cell,
        "getGridSquare",
        math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    )
    if square and call(square, "isVehicleIntersecting") == true then
        return "vehicle"
    end
    ensure(cell)
    key = tileKey(x, y, z)
    if cache.exact[key] then return "vehicle" end
    if includeClearance == true and cache.clearance[key] then
        return "vehicle_clearance"
    end
    return nil
end

return Avoidance
