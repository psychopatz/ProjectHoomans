PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal
local CampSite = PNC.Semantics and PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Geometry = PNC.Semantics and PNC.Semantics.CampSiteGeometry
    or require "PNC/Semantics/PNC_SemanticCampSiteGeometry"

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
        "sleepSlotId", "sleepSlotIndex", "sleepCapacity", "bedCapacity",
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
    local service = PNC.CampResourceService
    if service and service.GetCachedSnapshot then
        state = service.GetCachedSnapshot(record) or state
    end
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

function Internal.CampActivitySite(record, runtime, order)
    local state = record and record.campState or nil
    local service = PNC.CampResourceService
    local scope
    local bounds
    local anchorX
    local anchorY
    local anchorZ
    local campRadius
    if service and service.GetCachedSnapshot then
        state = service.GetCachedSnapshot(record) or state
    end
    anchorX, anchorY, anchorZ, campRadius =
        Internal.CampActivityBounds(record, runtime)
    scope = CampSite.NormalizeScope(runtime and runtime.scope)
        or CampSite.NormalizeScope(runtime and runtime.siteScope)
        or CampSite.NormalizeScope(state and state.scope)
        or CampSite.NormalizeScope(state and state.siteScope)
        or CampSite.NormalizeScope(order and order.scope)
        or CampSite.NormalizeScope(order and order.siteScope)
    bounds = CampSite.NormalizeBounds(runtime and runtime.roomBounds
        or state and state.roomBounds or order and order.roomBounds)
    if not scope then
        scope = bounds and CampSite.SCOPES.ROOM
            or CampSite.SCOPES.CAMPFIRE
    end
    return {
        kind = CampSite.KIND,
        scope = scope,
        siteScope = scope,
        siteID = runtime and runtime.siteID
            or state and state.siteID or order and order.siteID,
        roomID = runtime and runtime.roomID
            or state and state.roomID or order and order.roomID,
        buildingID = runtime and runtime.buildingID
            or state and state.buildingID or order and order.buildingID,
        roomType = runtime and runtime.roomType
            or state and state.roomType or order and order.roomType,
        roomName = runtime and runtime.roomName
            or state and state.roomName or order and order.roomName,
        roomBounds = bounds,
        campfireID = runtime and runtime.campfireID
            or state and state.campfireID or order and order.campfireID,
        x = anchorX,
        y = anchorY,
        z = anchorZ,
        radius = campRadius,
    }
end

local function pointInsideSite(site, x, y, z)
    if Geometry and Geometry.ContainsPoint then
        return Geometry.ContainsPoint(site, x, y, z, {
            radius = site and site.radius,
        })
    end
    if site and site.scope == CampSite.SCOPES.ROOM then
        return CampSite.BoundsContain(site.roomBounds,
            math.floor(tonumber(x) or -999999),
            math.floor(tonumber(y) or -999999), z)
    end
    local anchorX = tonumber(site and site.x)
    local anchorY = tonumber(site and site.y)
    local anchorZ = tonumber(site and site.z)
    local radius = tonumber(site and site.radius) or 3
    local targetX = tonumber(x)
    local targetY = tonumber(y)
    local targetZ = tonumber(z) or 0
    if not anchorX or not anchorY or not targetX or not targetY
        or math.abs(targetZ - (anchorZ or 0)) > 0.5
    then
        return false
    end
    local dx, dy = targetX - anchorX, targetY - anchorY
    return dx * dx + dy * dy <= (radius + 0.5) * (radius + 0.5)
end

local function bodyInsideRoom(site, record, zombie)
    local square
    local bodyX
    local bodyY
    local bodyZ
    if zombie and zombie.getCurrentSquare then
        square = zombie:getCurrentSquare()
    end
    if square and Geometry and Geometry.MatchesRoom then
        return Geometry.MatchesRoom(square, site) == true
    end
    bodyX = zombie and zombie.getX and zombie:getX()
        or record and record.x
    bodyY = zombie and zombie.getY and zombie:getY()
        or record and record.y
    bodyZ = zombie and zombie.getZ and zombie:getZ()
        or record and record.z
    return pointInsideSite(site, bodyX, bodyY, bodyZ)
end

function Internal.CampActivityIsSafe(record, zombie, runtime, order)
    if not runtime or runtime.campActivity ~= true then return true end
    local site = Internal.CampActivitySite(record, runtime, order)
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
    if site.scope == CampSite.SCOPES.ROOM then
        if not site.roomBounds then
            return false, "CAMP_ACTIVITY_ROOM_METADATA_MISSING"
        end
        if not pointInsideSite(site, targetX, targetY, targetZ) then
            return false, "CAMP_ACTIVITY_TARGET_OUTSIDE_ROOM"
        end
        if anchorTargetX and anchorTargetY and anchorTargetZ
            and not pointInsideSite(site, anchorTargetX,
                anchorTargetY, anchorTargetZ)
        then
            return false, "CAMP_ACTIVITY_TARGET_OUTSIDE_ROOM"
        end
        -- Do not require the body to be inside the room while it is still
        -- travelling to the selected target. Once arrival is settled, the
        -- room identity becomes the activity's temporary safety boundary.
        if zombie and (runtime.arrivalSettled == true
            or runtime.positioned == true
            or runtime.seatEntered == true
            or runtime.sleepSurfaceEntered == true)
            and not bodyInsideRoom(site, record, zombie)
        then
            return false, "CAMP_ACTIVITY_LEFT_ROOM"
        end
        return true
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
    -- This safety check runs before the movement branch below. Rejecting a
    -- body that is still travelling makes every campfire activity fail as
    -- soon as it starts, because the body is necessarily outside the small
    -- campfire radius at that moment. Once arrival is settled, the radius is
    -- the correct temporary outdoor boundary.
    if zombie and zombie.getX and zombie.getY
        and (runtime.arrivalSettled == true
            or runtime.positioned == true
            or runtime.seatEntered == true
            or runtime.sleepSurfaceEntered == true)
    then
        bodyDistanceFromCamp = PNC.Core.Distance(
            zombie:getX(), zombie:getY(), anchorX, anchorY)
        if bodyDistanceFromCamp > campRadius + 1.0 then
            return false, "CAMP_ACTIVITY_LEFT_AREA"
        end
    end
    return true
end

return Internal
