local Service = PNC.Travel.Service
local Internal = Service.Internal
local Projection = PNC.Travel.Projection

function Service.TickLive(recordOrID, body, atWorldHour)
    local record = Internal.ResolveRecord(recordOrID)
    local journey = record and record.travel or nil
    if not journey or not body then return nil, "journey_or_body_missing" end
    atWorldHour = tonumber(atWorldHour) or Internal.WorldHour()
    local previousState = journey.state
    local elapsed = math.max(
        0,
        atWorldHour - (tonumber(journey.lastAdvancedWorldHour) or atWorldHour)
    )

    Service.SyncLivePosition(record, body, atWorldHour)
    if journey.state == "waiting" then
        journey.waitRemainingWorldHours = math.max(
            0,
            (tonumber(journey.waitRemainingWorldHours) or 0) - elapsed
        )
        if journey.waitRemainingWorldHours <= 0 then
            journey.state = "en_route"
            journey.revision = (tonumber(journey.revision) or 0) + 1
            journey.lastStateReason = "wait_complete"
        end
    end

    if journey.state == "en_route" then
        local target = Service.GetCurrentTarget(record)
        if not target then
            Service.SetState(record, "arrived", "route_complete")
        else
            local x = body.getX and body:getX() or record.x
            local y = body.getY and body:getY() or record.y
            local z = body.getZ and body:getZ() or record.z
            local dx = (tonumber(target.x) or 0) - (tonumber(x) or 0)
            local dy = (tonumber(target.y) or 0) - (tonumber(y) or 0)
            local dz = (tonumber(target.z) or 0) - (tonumber(z) or 0)
            local radius = math.max(
                0.1,
                tonumber(target.stopDistance) or 1
            )
            if (dx * dx) + (dy * dy) + (dz * dz) <= radius * radius then
                Service.ReachCurrentWaypoint(record, atWorldHour)
            end
        end
    end

    if previousState ~= journey.state
        and previousState == "waiting"
        and journey.state == "en_route"
    then
        Internal.MarkChanged(record, "travel", "travel_wait_complete", false)
        Service.Emit(
            "state_changed",
            record,
            journey,
            previousState .. ":" .. journey.state
        )
    end
    if journey.state == "arrived" then
        Service.EnsureArrivalHandled(record, "live_arrival")
    end
    Projection.UpdateETA(journey, atWorldHour)
    return Service.GetCurrentTarget(record), journey.state
end

function Service.GetCurrentTarget(recordOrID)
    local record = Internal.ResolveRecord(recordOrID)
    local journey = record and record.travel or nil
    if not journey or not journey.route then return nil end
    local segment = journey.route.segments
        and journey.route.segments[journey.segmentIndex] or nil
    if not segment then return nil end
    return {
        x = segment.toX,
        y = segment.toY,
        z = segment.toZ,
        stopDistance = journey.arrivalRadius,
        mode = PNC.Travel.Providers.GetLiveMode(
            journey.speedProfile,
            journey.mode
        ),
        tag = segment.tag,
    }
end

function Service.OnMaterialized(record)
    local journey = record and record.travel or nil
    if not journey then return end
    Service.Advance(record, Internal.WorldHour())
    journey.controller = "live"
    journey.lastAdvancedWorldHour = Internal.WorldHour()
    Service.Emit("materialized", record, journey, "presence_live")
end

function Service.OnAbstracted(record, body)
    local journey = record and record.travel or nil
    if not journey then return end
    if body then
        Service.SyncLivePosition(record, body, Internal.WorldHour())
    end
    journey.controller = "abstract"
    journey.lastAdvancedWorldHour = Internal.WorldHour()
    Service.Emit("abstracted", record, journey, "presence_abstract")
end
