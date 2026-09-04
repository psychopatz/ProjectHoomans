--[[
    PNC Vehicle Occupancy Adapter
    Uses the native square intersection test for exact chassis occupancy.
    Native movement remains responsible for physical vehicle contact; PNC does
    not maintain a second vehicle registry, clearance ring, or route quarantine.
]]

PNC = PNC or {}
PNC.VehicleAvoidance = PNC.VehicleAvoidance or {}

local Avoidance = PNC.VehicleAvoidance

local function call(object, methodName, ...)
    local method
    local ok
    local result
    if not object then return nil end
    ok, method = pcall(function()
        return object[methodName]
    end)
    if not ok or type(method) ~= "function" then return nil end
    ok, result = pcall(method, object, ...)
    if not ok then return nil end
    return result
end

-- Kept as a compatibility boundary for callers that used to invalidate the
-- removed shared footprint cache.
function Avoidance.Invalidate()
end

function Avoidance.GetReason(x, y, z, cell)
    local square
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
    return nil
end

return Avoidance
