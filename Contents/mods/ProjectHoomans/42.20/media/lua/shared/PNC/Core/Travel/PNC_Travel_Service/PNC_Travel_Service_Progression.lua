local Service = PNC.Travel.Service
local Internal = Service.Internal
local Projection = PNC.Travel.Projection
local Route = PNC.Travel.Route

function Service.Advance(recordOrID, atWorldHour)
    local record = Internal.ResolveRecord(recordOrID)
    local journey = record and record.travel or nil
    if not journey then return nil, false end
    local previousState = journey.state
    local previousX = tonumber(record.x) or 0
    local previousY = tonumber(record.y) or 0
    local projected, changed = Projection.AdvanceMutable(
        journey,
        tonumber(atWorldHour) or Internal.WorldHour()
    )
    record.x = projected.x or record.x
    record.y = projected.y or record.y
    record.z = projected.z or record.z
    if changed and (
        math.floor(previousX) ~= math.floor(record.x)
        or math.floor(previousY) ~= math.floor(record.y)
    ) then
        -- Client maps extrapolate between sparse corrections. Persist the
        -- authoritative coordinate without emitting a route-bearing network
        -- delta for every abstract movement step.
        Internal.MarkDirty(record, "travel_progress")
    end
    if previousState ~= journey.state then
        journey.revision = (tonumber(journey.revision) or 0) + 1
        journey.lastStateReason = journey.state
        if journey.state == "arrived" then
            Service.EnsureArrivalHandled(
                record,
                "route_complete",
                false
            )
        end
        Internal.MarkChanged(record, "travel", "travel_state", false)
        Service.Emit(
            "state_changed",
            record,
            journey,
            previousState .. ":" .. tostring(journey.state)
        )
        if journey.state == "arrived" then
            Service.Emit(
                "arrived",
                record,
                journey,
                "route_complete"
            )
        end
    elseif journey.state == "arrived" then
        Service.EnsureArrivalHandled(record, "arrival_recovery")
    end
    return projected, changed
end

function Service.SyncLivePosition(recordOrID, body, atWorldHour)
    local record = Internal.ResolveRecord(recordOrID)
    local journey = record and record.travel or nil
    if not journey or not body then return nil, false end
    local x = body.getX and body:getX() or record.x
    local y = body.getY and body:getY() or record.y
    local z = body.getZ and body:getZ() or record.z
    local distance = Route.ProjectWorldPosition(
        journey.route,
        x,
        y,
        z,
        journey.distanceTravelled
    )
    local changed = distance > (tonumber(journey.distanceTravelled) or 0)
        + 0.001
    journey.distanceTravelled = math.max(
        tonumber(journey.distanceTravelled) or 0,
        math.min(tonumber(journey.distanceTotal) or 0, distance)
    )
    journey.lastAdvancedWorldHour = tonumber(atWorldHour) or Internal.WorldHour()
    journey.controller = "live"
    local projected = Route.Project(
        journey.route,
        journey.distanceTravelled,
        journey.segmentIndex
    )
    journey.segmentIndex = projected.segmentIndex
    journey.segmentProgress = projected.segmentProgress
    Projection.UpdateETA(journey, journey.lastAdvancedWorldHour)
    record.x = tonumber(x) or record.x
    record.y = tonumber(y) or record.y
    record.z = tonumber(z) or record.z
    return journey, changed
end

function Service.ReachCurrentWaypoint(recordOrID, atWorldHour)
    local record = Internal.ResolveRecord(recordOrID)
    local journey = record and record.travel or nil
    local segment = journey and journey.route
        and journey.route.segments
        and journey.route.segments[journey.segmentIndex] or nil
    if not segment then return false, "segment_missing" end
    local previous = journey.state
    journey.distanceTravelled = segment.distanceEnd
    journey.lastAdvancedWorldHour = tonumber(atWorldHour) or Internal.WorldHour()
    if journey.distanceTravelled >= journey.distanceTotal - 0.0001 then
        journey.distanceTravelled = journey.distanceTotal
        journey.state = "arrived"
        journey.arrivedWorldHour = journey.lastAdvancedWorldHour
    elseif (tonumber(segment.waitWorldHours) or 0) > 0 then
        journey.state = "waiting"
        journey.waitRemainingWorldHours = segment.waitWorldHours
        journey.segmentIndex = math.min(
            #journey.route.segments,
            journey.segmentIndex + 1
        )
    else
        journey.segmentIndex = math.min(
            #journey.route.segments,
            journey.segmentIndex + 1
        )
    end
    local projected = Route.Project(
        journey.route,
        journey.distanceTravelled,
        journey.segmentIndex
    )
    record.x = projected.x
    record.y = projected.y
    record.z = projected.z
    journey.segmentProgress = projected.segmentProgress
    journey.revision = (tonumber(journey.revision) or 0) + 1
    Projection.UpdateETA(journey, journey.lastAdvancedWorldHour)
    if journey.state == "arrived" then
        Service.EnsureArrivalHandled(
            record,
            "route_complete",
            false
        )
    end
    Internal.MarkChanged(record, "travel", "travel_waypoint", false)
    if previous ~= journey.state then
        Service.Emit(
            "state_changed",
            record,
            journey,
            previous .. ":" .. journey.state
        )
    end
    if journey.state == "arrived" then
        Service.Emit(
            "arrived",
            record,
            journey,
            "route_complete"
        )
    end
    return true, journey.state
end
