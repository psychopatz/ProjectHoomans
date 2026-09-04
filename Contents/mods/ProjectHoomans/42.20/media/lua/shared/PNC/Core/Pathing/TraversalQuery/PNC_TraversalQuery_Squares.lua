-- Square lookup, occupancy, and materialization safety queries.

PNC = PNC or {}
PNC.TraversalQuery = PNC.TraversalQuery or {}
PNC.TraversalQuery.Internal = PNC.TraversalQuery.Internal or {}

local TraversalQuery = PNC.TraversalQuery
local Internal = TraversalQuery.Internal
local VehicleAvoidance = PNC.VehicleAvoidance

function TraversalQuery.GetSquare(x, y, z, cell)
    cell = cell or (getCell and getCell() or nil)
    if not cell then
        return nil
    end
    return cell:getGridSquare(
        math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    )
end

function TraversalQuery.GetOccupancyReason(x, y, z, cell)
    local square = TraversalQuery.GetSquare(x, y, z, cell)
    local vehicleReason
    if not square then return "unloaded" end
    if VehicleAvoidance and VehicleAvoidance.GetReason then
        vehicleReason = VehicleAvoidance.GetReason(x, y, z, cell, false)
    elseif Internal.ObjectBool(square, { "isVehicleIntersecting" }, false) then
        vehicleReason = "vehicle"
    end
    if vehicleReason then return vehicleReason end
    if square:isSolid() then return "solid" end
    if square:isSolidTrans() then return "solid_trans" end
    if not square:isFree(false) then return "occupied" end
    return nil
end

function TraversalQuery.CanOccupy(x, y, z, cell)
    return TraversalQuery.GetOccupancyReason(x, y, z, cell) == nil
end

function TraversalQuery.GetTraversalOccupancyReason(x, y, z, cell)
    return TraversalQuery.GetOccupancyReason(x, y, z, cell)
end

function TraversalQuery.CanTraverseAt(x, y, z, cell)
    return TraversalQuery.GetTraversalOccupancyReason(x, y, z, cell) == nil
end

function TraversalQuery.FindNearestOccupable(x, y, z, maxRadius, cell)
    return Internal.FindNearestByReason(
        x,
        y,
        z,
        maxRadius,
        cell,
        TraversalQuery.GetOccupancyReason
    )
end

function TraversalQuery.GetMaterializationOccupancyReason(x, y, z, cell)
    local square = TraversalQuery.GetSquare(x, y, z, cell)
    local reason = TraversalQuery.GetOccupancyReason(x, y, z, cell)
    if reason then
        return reason
    end
    if square.hasFloor and not square:hasFloor() then
        return "no_floor"
    end
    return Internal.GetMaterializationObstacle(square)
end

function TraversalQuery.CanMaterializeAt(x, y, z, cell)
    return TraversalQuery.GetMaterializationOccupancyReason(x, y, z, cell) == nil
end

function TraversalQuery.FindNearestMaterializationSquare(x, y, z, maxRadius, cell)
    return Internal.FindNearestByReason(
        x,
        y,
        z,
        maxRadius,
        cell,
        TraversalQuery.GetMaterializationOccupancyReason
    )
end
