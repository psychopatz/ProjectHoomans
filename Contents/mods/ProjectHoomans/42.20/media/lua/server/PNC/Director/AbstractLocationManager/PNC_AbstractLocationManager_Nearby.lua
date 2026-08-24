if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AbstractLocations = PNC.AbstractLocations or {}
PNC.AbstractLocationManagerInternal =
    PNC.AbstractLocationManagerInternal or {}

local Locations = PNC.AbstractLocations
local H = PNC.AbstractLocationManagerInternal
local Store = PNC.AbstractWorldStore
local Types = PNC.AbstractWorldTypes
local Config = PNC.DirectorConfig
local Core = PNC.Core

function Locations.GetNearby(x, y, radius, limit)
    Store.EnsureLoaded()
    H.EnsureIndex()
    local size = Config.LOCATION_CELL_SIZE
    radius = math.max(0, tonumber(radius) or 0)
    limit = math.max(1, math.floor(tonumber(limit) or 2147483647))
    local minX, maxX = math.floor((x - radius) / size),
        math.floor((x + radius) / size)
    local minY, maxY = math.floor((y - radius) / size),
        math.floor((y + radius) / size)
    local output = {}
    for cx = minX, maxX do
        for cy = minY, maxY do
            local bucket = Locations.Cells[tostring(cx) .. ":" .. tostring(cy)]
            for _, location in pairs(bucket or {}) do
                local dx, dy = location.x - x, location.y - y
                local distanceSq = dx * dx + dy * dy
                if distanceSq <= radius * radius then
                    output[#output + 1] = { location = location,
                        distance = math.sqrt(distanceSq) }
                end
            end
        end
    end
    table.sort(output, function(a, b)
        return a.distance == b.distance and a.location.id < b.location.id
            or a.distance < b.distance
    end)
    while #output > limit do table.remove(output) end
    return output
end

return Locations

