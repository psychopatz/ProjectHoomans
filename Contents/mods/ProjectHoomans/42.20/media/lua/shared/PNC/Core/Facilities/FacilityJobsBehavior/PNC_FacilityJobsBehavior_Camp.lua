PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal

function Internal.RefreshCampActivity(record, zombie)
    local runtime = Internal.State(record)
    if not runtime or runtime.campActivity ~= true then return true end
    if not PNC.CampResourceService
        or not PNC.CampResourceService.RefreshActivity
    then return true end
    local ok, reason = PNC.CampResourceService.RefreshActivity(record, zombie)
    if ok == false then
        runtime.failedReason = reason
            or runtime.seating == true
            and "CAMP_SEAT_TARGET_UNAVAILABLE"
            or "CAMP_SLEEP_TARGET_UNAVAILABLE"
        return false
    end
    return true
end

function Internal.SleepTargetChanged(order, runtime, previous)
    if not previous then return false end
    if tostring(runtime and runtime.resourceKey or "")
        ~= tostring(previous.resourceKey or "")
        or tostring(runtime and runtime.sleepSurface or "")
            ~= tostring(previous.sleepSurface or "")
    then
        return true
    end
    local fields = {
        "x", "y", "z", "interactionX", "interactionY", "interactionZ",
        "sleepAnchorX", "sleepAnchorY", "sleepAnchorZ", "sleepAxis",
        "sleepFacing", "sleepSprite", "sleepGridX", "sleepGridY",
        "sleepGridWidth", "sleepGridHeight",
    }
    for index = 1, #fields do
        local field = fields[index]
        local left = order and order[field]
        local right = previous[field]
        if type(left) == "number" or type(right) == "number" then
            if math.abs((tonumber(left) or 0) - (tonumber(right) or 0)) > 0.02
            then
                return true
            end
        elseif tostring(left or "") ~= tostring(right or "") then
            return true
        end
    end
    return false
end

function Internal.CampActivityBounds(record, runtime)
    local state = record and record.campState or nil
    local anchorX = tonumber(runtime and runtime.campX)
        or tonumber(state and state.anchorX)
        or tonumber(record and record.anchorX)
        or tonumber(record and record.x)
        or 0
    local anchorY = tonumber(runtime and runtime.campY)
        or tonumber(state and state.anchorY)
        or tonumber(record and record.anchorY)
        or tonumber(record and record.y)
        or 0
    local anchorZ = tonumber(runtime and runtime.campZ)
        or tonumber(state and state.anchorZ)
        or tonumber(record and record.anchorZ)
        or tonumber(record and record.z)
        or 0
    local campRadius = tonumber(runtime and runtime.campRadius)
        or tonumber(state and state.campRadius)
        or tonumber(record and record.orderSpec
            and record.orderSpec.radius)
        or tonumber(PNC.Const and PNC.Const.CAMP_RADIUS)
        or 3
    local resourceRadius = tonumber(runtime and runtime.resourceRadius)
        or tonumber(state and state.resourceRadius)
        or tonumber(PNC.Const and PNC.Const.CAMP_RESOURCE_RADIUS)
        or 12
    return anchorX, anchorY, anchorZ,
        math.max(0.5, math.min(24, campRadius)),
        math.max(1, math.min(24, resourceRadius))
end

function Internal.CampActivityIsSafe(record, zombie, runtime, order)
    if not runtime or runtime.campActivity ~= true then return true end
    local anchorX, anchorY, anchorZ, campRadius =
        Internal.CampActivityBounds(record, runtime)
    local targetX = tonumber(order and order.x)
    local targetY = tonumber(order and order.y)
    local targetZ = tonumber(order and order.z)
    local anchorTargetX = tonumber(runtime and runtime.seatAnchor
        and runtime.seatAnchor.x)
        or tonumber(order and order.seatAnchorX)
    local anchorTargetY = tonumber(runtime and runtime.seatAnchor
        and runtime.seatAnchor.y)
        or tonumber(order and order.seatAnchorY)
    local anchorTargetZ = tonumber(runtime and runtime.seatAnchor
        and runtime.seatAnchor.z)
        or tonumber(order and order.seatAnchorZ)
    local targetDistance
    local anchorDistance
    local bodyDistanceFromCamp
    if not targetX or not targetY or not targetZ
        or math.abs(targetZ - anchorZ) > 0.5
    then
        return false, "CAMP_ACTIVITY_TARGET_INVALID"
    end
    targetDistance = PNC.Core.Distance(
        targetX, targetY, anchorX, anchorY)
    if targetDistance > campRadius + 0.5 then
        return false, "CAMP_ACTIVITY_TARGET_OUT_OF_RANGE"
    end
    if anchorTargetX and anchorTargetY and anchorTargetZ then
        if math.abs(anchorTargetZ - anchorZ) > 0.5 then
            return false, "CAMP_ACTIVITY_TARGET_INVALID"
        end
        anchorDistance = PNC.Core.Distance(
            anchorTargetX, anchorTargetY, anchorX, anchorY)
        if anchorDistance > campRadius + 0.5 then
            return false, "CAMP_ACTIVITY_TARGET_OUT_OF_RANGE"
        end
    end
    if zombie and zombie.getX and zombie.getY then
        bodyDistanceFromCamp = PNC.Core.Distance(
            zombie:getX(), zombie:getY(), anchorX, anchorY)
        if bodyDistanceFromCamp > campRadius + 1.0 then
            return false, "CAMP_ACTIVITY_LEFT_AREA"
        end
    end
    return true
end

return Internal
