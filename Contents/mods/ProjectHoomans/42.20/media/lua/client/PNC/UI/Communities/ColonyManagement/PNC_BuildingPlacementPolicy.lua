PNC = PNC or {}

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Policy = {}

local function currentSettlement()
    local network = PNC.Network
    local state = network and network.ClientState or nil
    local snapshot = state and state.colonyManagement or nil
    return type(snapshot) == "table" and snapshot.settlement or nil
end

local function pointFromSquare(square)
    if not square then return nil end
    local function read(method)
        if type(square[method]) ~= "function" then return nil end
        local ok, value = pcall(square[method], square)
        return ok and tonumber(value) or nil
    end
    local x, y, z = read("getX"), read("getY"), read("getZ")
    if not x or not y or not z then return nil end
    return x, y, z
end

-- BuildingService validates the blueprint anchor against the base's XY
-- territory. Keep the client preview aligned with that authoritative rule;
-- the server remains the final authority if the snapshot is stale.
function Policy.IsPointInsideBase(settlement, x, y, z)
    local geometry = settlement and settlement.geometry
    local region = geometry and geometry.region or nil
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not region or not x or not y then return false end
    if GridRegion.containsXY then
        return GridRegion.containsXY(region, math.floor(x), math.floor(y))
            == true
    end
    if GridRegion.containsPoint and z then
        return GridRegion.containsPoint(region, math.floor(x), math.floor(y),
            math.floor(z)) == true
    end
    return false
end

function Policy.ValidatePoint(settlement, x, y, z)
    if not settlement then return false, "BUILD_BASE_UNAVAILABLE" end
    if not tonumber(x) or not tonumber(y) or not tonumber(z) then
        return false, "BUILD_TARGET_REQUIRED"
    end
    if not Policy.IsPointInsideBase(settlement, x, y, z) then
        return false, "BUILD_TARGET_OUTSIDE_BASE"
    end
    return true
end

function Policy.ValidateSquare(settlement, square)
    local x, y, z = pointFromSquare(square)
    return Policy.ValidatePoint(settlement, x, y, z)
end

function Policy.CurrentSettlement()
    return currentSettlement()
end

function Policy.ValidateCurrentPoint(x, y, z)
    return Policy.ValidatePoint(currentSettlement(), x, y, z)
end

function Policy.ValidateCurrentSquare(square)
    return Policy.ValidateSquare(currentSettlement(), square)
end

return Policy
