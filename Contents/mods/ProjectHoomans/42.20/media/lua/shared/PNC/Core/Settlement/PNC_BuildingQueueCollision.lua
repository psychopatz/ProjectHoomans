-- Shared collision helpers for queued native building blueprints.
--
-- The client uses this for placement feedback and the server uses it as the
-- authoritative queue gate. Both sides therefore compare the same occupied
-- tile footprint instead of only comparing blueprint anchors.

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Footprint = require "PNC/Core/Settlement/PNC_BuildingFootprint"
local Collision = {}

local function active(order)
    local status = tostring(order and order.status or "")
    return status ~= "COMPLETED" and status ~= "CANCELLED"
        and status ~= "FAILED"
end

local function orderId(order)
    return tostring(order and order.id or "")
end

function Collision.FootprintForBlueprint(blueprint, nativeObjectInfo)
    if type(blueprint) ~= "table" then return nil end
    return Footprint.FromObjectInfo(nativeObjectInfo,
        blueprint.nSprite, blueprint.x, blueprint.y, blueprint.z)
end

function Collision.FootprintForOrder(order, resolveNativeObjectInfo)
    local blueprint = order and order.blueprint or nil
    local info = resolveNativeObjectInfo and resolveNativeObjectInfo(blueprint)
        or nil
    return Collision.FootprintForBlueprint(blueprint, info)
end

-- Returns the first conflicting order and the intersecting region.
-- `orders` may be either an array or a repository map.
function Collision.Find(footprint, orders, resolveNativeObjectInfo,
    excludedOrderId)
    if not footprint or type(GridRegion.intersects) ~= "function" then
        return nil, nil
    end
    excludedOrderId = excludedOrderId and tostring(excludedOrderId) or nil
    for _, order in pairs(orders or {}) do
        if active(order)
            and (not excludedOrderId or orderId(order) ~= excludedOrderId)
        then
            local other = Collision.FootprintForOrder(order,
                resolveNativeObjectInfo)
            if other and GridRegion.intersects(footprint, other) then
                return order, GridRegion.intersection(footprint, other)
            end
        end
    end
    return nil, nil
end

function Collision.Active(order)
    return active(order)
end

return Collision
