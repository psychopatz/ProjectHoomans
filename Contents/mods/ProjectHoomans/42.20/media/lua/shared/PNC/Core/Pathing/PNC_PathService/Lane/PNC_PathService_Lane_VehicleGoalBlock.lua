-- Vehicle-occupied goal quarantine and release policy.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal

function Internal.clearVehicleBlockedGoal(lane)
    if not lane then return end
    lane.vehicleBlockedGoalX = nil
    lane.vehicleBlockedGoalY = nil
    lane.vehicleBlockedGoalZ = nil
    lane.vehicleBlockedFromX = nil
    lane.vehicleBlockedFromY = nil
    lane.vehicleBlockedFromZ = nil
    lane.vehicleBlockedAt = 0
    lane.vehicleBlockedReason = nil
end

function Internal.isVehicleBlockedGoal(lane, intent)
    local dx
    local dy
    local dz
    local distance
    local query
    local occupancyReason
    if not lane or not intent or intent.kind ~= "move"
        or lane.vehicleBlockedGoalX == nil
        or lane.vehicleBlockedFromX == nil
    then
        return false
    end
    dx = (tonumber(intent.x) or 0) - lane.vehicleBlockedGoalX
    dy = (tonumber(intent.y) or 0) - lane.vehicleBlockedGoalY
    dz = (tonumber(intent.z) or 0) - (tonumber(lane.vehicleBlockedGoalZ) or 0)
    distance = math.sqrt((dx * dx) + (dy * dy))
    if distance >= Internal.VEHICLE_BLOCKED_GOAL_CHANGE_DISTANCE
        or math.abs(dz) >= 1
    then
        Internal.clearVehicleBlockedGoal(lane)
        return false
    end
    query = Internal.TraversalQuery or PNC.TraversalQuery
    occupancyReason = query and query.GetOccupancyReason
        and query.GetOccupancyReason(
            lane.vehicleBlockedFromX,
            lane.vehicleBlockedFromY,
            lane.vehicleBlockedFromZ
        )
        or nil
    if occupancyReason ~= "vehicle" then
        Internal.clearVehicleBlockedGoal(lane)
        return false
    end
    return true
end
