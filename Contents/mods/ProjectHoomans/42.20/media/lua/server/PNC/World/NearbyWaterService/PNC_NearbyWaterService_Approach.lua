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

function H.FacingToward(fromX, fromY, toX, toY)
    local dx, dy = toX - fromX, toY - fromY
    local vertical = dy > 0.25 and "S" or dy < -0.25 and "N" or ""
    local horizontal = dx > 0.25 and "E" or dx < -0.25 and "W" or ""
    return vertical .. horizontal
end

function H.CanOccupy(x, y, z)
    local internal = PNC.PathService and PNC.PathService.Internal
    if internal and internal.isSquareWalkable then
        local ok, walkable = pcall(internal.isSquareWalkable, x, y, z)
        if ok then return walkable == true end
    end
    local cell = getCell and getCell() or nil
    local square = cell and cell.getGridSquare
        and cell:getGridSquare(math.floor(x), math.floor(y), z) or nil
    if not square then return false end
    if type(square.isFree) == "function" then
        local ok, free = pcall(square.isFree, square, false)
        if ok then return free == true end
    end
    return true
end

function Service.BuildApproach(record, entry)
    if not record or not entry then return nil, "WATER_SOURCE_UNAVAILABLE" end
    local sourceX, sourceY, sourceZ = tonumber(entry.x), tonumber(entry.y),
        tonumber(entry.z) or 0
    if sourceX == nil or sourceY == nil then
        return nil, "WATER_SOURCE_POSITION_MISSING"
    end
    local origin = H.OriginFor(record)
    local originX = origin and tonumber(H.Call(origin, "getX")) or sourceX
    local originY = origin and tonumber(H.Call(origin, "getY")) or sourceY
    local candidates = {}
    local baseX, baseY = math.floor(sourceX), math.floor(sourceY)
    for _, offset in ipairs(APPROACH_OFFSETS) do
        local x, y = baseX + offset.x + 0.5, baseY + offset.y + 0.5
        if H.CanOccupy(x, y, sourceZ) then
            local dx, dy = x - originX, y - originY
            candidates[#candidates + 1] = {
                x = x, y = y, z = sourceZ,
                interactionFacing = H.FacingToward(x, y, sourceX, sourceY),
                approachKey = tostring(math.floor(x)) .. ":"
                    .. tostring(math.floor(y)) .. ":" .. tostring(sourceZ),
                distSq = dx * dx + dy * dy,
            }
        end
    end
    table.sort(candidates, function(a, b)
        if a.distSq ~= b.distSq then return a.distSq < b.distSq end
        return a.approachKey < b.approachKey
    end)
    if #candidates == 0 then return nil, "WATER_APPROACH_UNAVAILABLE" end
    for _, candidate in ipairs(candidates) do candidate.distSq = nil end
    return candidates[1], candidates
end

return Service

