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

function H.LiveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

function H.OriginFor(record)
    local body = H.LiveBody(record)
    if body then return body end
    if not record or record.x == nil or record.y == nil then return nil end
    return {
        getX = function() return record.x end,
        getY = function() return record.y end,
        getZ = function() return record.z or 0 end,
    }
end

function H.ListSize(list)
    return list and list.size and list:size() or 0
end

function H.ListItem(list, index)
    return list and list.get and list:get(index) or nil
end

function H.SquarePosition(square)
    local x, y, z = H.Call(square, "getX"), H.Call(square, "getY"),
        H.Call(square, "getZ")
    if x == nil or y == nil then return nil end
    return tonumber(x) + 0.5, tonumber(y) + 0.5, tonumber(z) or 0
end

return Service

