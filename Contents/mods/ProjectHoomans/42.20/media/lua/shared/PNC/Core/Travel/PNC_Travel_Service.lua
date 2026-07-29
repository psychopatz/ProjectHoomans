--[[
    Server-authoritative journey lifecycle and record integration.

    Other systems interact through this service (or PNC.API.Travel), never by
    mutating record.travel directly. Presence remains an interchangeable body
    representation; the journey remains canonical across both modes.
]]

PNC = PNC or {}
PNC.Travel = PNC.Travel or {}
PNC.Travel.Service = PNC.Travel.Service or {}

local Service = PNC.Travel.Service
local Core = PNC.Core
local Const = PNC.Const
local Model = PNC.Travel.Model
local Projection = PNC.Travel.Projection
local Route = PNC.Travel.Route
local Arrivals = PNC.Travel.Arrivals

Service.Listeners = Service.Listeners or {}
Service.LastPositionRefreshAt = Service.LastPositionRefreshAt or 0

local EVENT_NAMES = {
    started = "OnPNCTravelStarted",
    state_changed = "OnPNCTravelStateChanged",
    arrived = "OnPNCTravelArrived",
    cancelled = "OnPNCTravelCancelled",
    materialized = "OnPNCTravelMaterialized",
    abstracted = "OnPNCTravelAbstracted",
}

local function worldHour()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and tonumber(gameTime:getWorldAgeHours())
        or 0
end

local function resolveRecord(recordOrID)
    if type(recordOrID) == "table" then return recordOrID end
    return PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(recordOrID) or nil
end

local function markDirty(record, domain)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, domain or "travel")
    end
end

local function markChanged(record, domain, eventName, includeRoute)
    markDirty(record, domain)
    if PNC.Network and PNC.Network.QueueRosterDelta then
        PNC.Network.QueueRosterDelta(
            record,
            false,
            eventName or "travel",
            includeRoute == true
        )
    end
end

function Service.WorldHour()
    return worldHour()
end

function Service.RegisterListener(eventName, listener)
    eventName = tostring(eventName or "")
    if eventName == "" or type(listener) ~= "function" then return false end
    Service.Listeners[eventName] = Service.Listeners[eventName] or {}
    Service.Listeners[eventName][#Service.Listeners[eventName] + 1] = listener
    return true
end

function Service.UnregisterListener(eventName, listener)
    eventName = tostring(eventName or "")
    local listeners = Service.Listeners[eventName]
    local i
    if eventName == "" or type(listener) ~= "function"
        or type(listeners) ~= "table"
    then
        return false
    end
    for i = #listeners, 1, -1 do
        if listeners[i] == listener then
            table.remove(listeners, i)
            if #listeners <= 0 then
                Service.Listeners[eventName] = nil
            end
            return true
        end
    end
    return false
end

function Service.Emit(eventName, record, journey, reason)
    local listeners = Service.Listeners[tostring(eventName or "")] or {}
    local i
    local ok
    local listenerError
    for i = 1, #listeners do
        ok, listenerError = pcall(
            listeners[i],
            record,
            journey,
            reason
        )
        if not ok and Core and Core.LogWarn then
            Core.LogWarn(
                "PNC travel listener failed event="
                    .. tostring(eventName)
                    .. " index=" .. tostring(i)
                    .. " error=" .. tostring(listenerError)
            )
        end
    end
    local luaEvent = EVENT_NAMES[eventName]
    if luaEvent and triggerEvent then
        pcall(triggerEvent, luaEvent, record, journey, reason)
    end
end

function Service.EnsureArrivalHandled(recordOrID, reason, replicate)
    local record = resolveRecord(recordOrID)
    local journey = record and record.travel or nil
    local wasHandled
    local handled
    local handledReason
    if not journey or journey.state ~= "arrived" then
        return false, "not_arrived"
    end
    if not Arrivals or not Arrivals.Dispatch then
        return false, "arrival_dispatch_unavailable"
    end
    wasHandled = journey.arrivalHandled == true
    handled, handledReason = Arrivals.Dispatch(
        record,
        journey,
        reason or "arrived"
    )
    if handled and not wasHandled and replicate ~= false then
        markChanged(
            record,
            "order",
            "travel_arrival",
            false
        )
    end
    return handled, handledReason
end

function Service.Get(recordOrID)
    local record = resolveRecord(recordOrID)
    return record and record.travel or nil
end

function Service.Start(recordOrID, request)
    local record = resolveRecord(recordOrID)
    if not record or record.alive == false then
        return nil, "npc_missing"
    end
    if Core.IsAuthority and not Core.IsAuthority() then
        return nil, "not_authority"
    end
    if type(request) ~= "table"
        or type(request.destination) ~= "table"
            and (request.x == nil or request.y == nil)
    then
        return nil, "destination_missing"
    end
    if Model.IsActive(record.travel) then
        Service.Cancel(record, "replaced")
    end
    local nowHour = worldHour()
    local journey = Model.New(record, request, nowHour)
    record.travel = journey
    record.orderSpec = {
        kind = Const.ORDER_TRAVEL or "travel",
        journeyId = journey.journeyId,
    }
    record.runtime = record.runtime or {}
    record.runtime.target = nil
    record.runtime.forcePresenceCheck = true
    record.nextThinkAt = Core.Now()
    Projection.AdvanceMutable(journey, nowHour)
    record.x = journey.x or record.x
    record.y = journey.y or record.y
    record.z = journey.z or record.z
    if journey.state == "arrived" then
        Service.EnsureArrivalHandled(
            record,
            "already_at_destination",
            false
        )
    end
    markChanged(record, "travel", "travel_started", true)
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, nil, Core.Now())
    end
    if PNC.Scheduler and PNC.Scheduler.Schedule then
        PNC.Scheduler.Schedule(
            record,
            Core.Now() + (tonumber(PNC.Scheduler.SLOT_MS) or 50)
        )
    end
    Service.Emit("started", record, journey, "started")
    if journey.state == "arrived" then
        Service.Emit(
            "arrived",
            record,
            journey,
            "already_at_destination"
        )
    end
    return journey
end

function Service.SetState(record, state, reason)
    local journey = record and record.travel or nil
    if not journey then return false, "journey_missing" end
    state = tostring(state or "")
    if state == "" or journey.state == state then return false, "unchanged" end
    local previous = journey.state
    journey.state = state
    journey.lastStateReason = tostring(reason or state)
    journey.revision = (tonumber(journey.revision) or 0) + 1
    if state == "arrived" then
        journey.arrivedWorldHour = worldHour()
        Service.EnsureArrivalHandled(
            record,
            reason or "arrived",
            false
        )
    elseif state == "paused" then
        journey.pausedWorldHour = worldHour()
    end
    markChanged(record, "travel", "travel_state", false)
    Service.Emit("state_changed", record, journey, previous .. ":" .. state)
    if state == "arrived" then
        Service.Emit(
            "arrived",
            record,
            journey,
            reason or "arrived"
        )
    elseif state == "cancelled" then
        Service.Emit("cancelled", record, journey, reason or "cancelled")
    end
    return true
end

function Service.Pause(recordOrID, reason)
    local record = resolveRecord(recordOrID)
    if not record or not Model.IsActive(record.travel) then
        return false, "journey_inactive"
    end
    Service.Advance(record, worldHour())
    return Service.SetState(record, "paused", reason or "paused")
end

function Service.Resume(recordOrID, reason)
    local record = resolveRecord(recordOrID)
    local journey = record and record.travel or nil
    if not journey or journey.state ~= "paused" then
        return false, "journey_not_paused"
    end
    journey.lastAdvancedWorldHour = worldHour()
    return Service.SetState(record, "en_route", reason or "resumed")
end

function Service.Cancel(recordOrID, reason)
    local record = resolveRecord(recordOrID)
    if not record or not Model.IsActive(record.travel) then
        return false, "journey_inactive"
    end
    Service.Advance(record, worldHour())
    return Service.SetState(record, "cancelled", reason or "cancelled")
end

function Service.Retarget(recordOrID, request)
    local record = resolveRecord(recordOrID)
    local previous = record and record.travel or nil
    if not record or not previous then return nil, "journey_missing" end
    request = type(request) == "table" and request or {}
    if type(request.destination) ~= "table"
        and (request.x == nil or request.y == nil)
    then
        return nil, "destination_missing"
    end
    if record.presenceState == Const.PRESENCE_LIVE then
        local body = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
        if body then Service.SyncLivePosition(record, body, worldHour()) end
    else
        Service.Advance(record, worldHour())
    end
    request.origin = {
        x = record.x,
        y = record.y,
        z = record.z,
    }
    request.journeyId = previous.journeyId
    request.ownerMod = request.ownerMod or previous.ownerMod
    request.ownerRef = request.ownerRef or previous.ownerRef
    request.visibility = request.visibility or previous.visibility
    request.metadata = request.metadata or previous.metadata
    if request.arrivalAction == nil and request.onArrival == nil then
        request.arrivalAction = previous.arrivalAction
    end
    local replacement = Model.New(record, request, worldHour())
    replacement.routeVersion = (tonumber(previous.routeVersion) or 0) + 1
    replacement.revision = (tonumber(previous.revision) or 0) + 1
    replacement.lastStateReason = "retargeted"
    record.travel = replacement
    record.orderSpec = {
        kind = Const.ORDER_TRAVEL or "travel",
        journeyId = replacement.journeyId,
    }
    markChanged(record, "travel", "travel_retargeted", true)
    Service.Emit("state_changed", record, replacement, "retargeted")
    return replacement
end

function Service.Advance(recordOrID, atWorldHour)
    local record = resolveRecord(recordOrID)
    local journey = record and record.travel or nil
    if not journey then return nil, false end
    local previousState = journey.state
    local previousX = tonumber(record.x) or 0
    local previousY = tonumber(record.y) or 0
    local projected, changed = Projection.AdvanceMutable(
        journey,
        tonumber(atWorldHour) or worldHour()
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
        markDirty(record, "travel_progress")
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
        markChanged(record, "travel", "travel_state", false)
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
    local record = resolveRecord(recordOrID)
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
    journey.lastAdvancedWorldHour = tonumber(atWorldHour) or worldHour()
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
    local record = resolveRecord(recordOrID)
    local journey = record and record.travel or nil
    local segment = journey and journey.route
        and journey.route.segments
        and journey.route.segments[journey.segmentIndex] or nil
    if not segment then return false, "segment_missing" end
    local previous = journey.state
    journey.distanceTravelled = segment.distanceEnd
    journey.lastAdvancedWorldHour = tonumber(atWorldHour) or worldHour()
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
    markChanged(record, "travel", "travel_waypoint", false)
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

function Service.TickLive(recordOrID, body, atWorldHour)
    local record = resolveRecord(recordOrID)
    local journey = record and record.travel or nil
    if not journey or not body then return nil, "journey_or_body_missing" end
    atWorldHour = tonumber(atWorldHour) or worldHour()
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
        markChanged(record, "travel", "travel_wait_complete", false)
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
    local record = resolveRecord(recordOrID)
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
    Service.Advance(record, worldHour())
    journey.controller = "live"
    journey.lastAdvancedWorldHour = worldHour()
    Service.Emit("materialized", record, journey, "presence_live")
end

function Service.OnAbstracted(record, body)
    local journey = record and record.travel or nil
    if not journey then return end
    if body then
        Service.SyncLivePosition(record, body, worldHour())
    end
    journey.controller = "abstract"
    journey.lastAdvancedWorldHour = worldHour()
    Service.Emit("abstracted", record, journey, "presence_abstract")
end

function Service.RefreshAbstractPositions(nowMs, force)
    nowMs = tonumber(nowMs) or Core.Now()
    if force ~= true and nowMs - (tonumber(Service.LastPositionRefreshAt) or 0)
        < (tonumber(Const.TRAVEL_POSITION_REFRESH_MS) or 250)
    then
        return 0
    end
    Service.LastPositionRefreshAt = nowMs
    local count = 0
    local hour = worldHour()
    if not PNC.Registry or not PNC.Registry.ForEach then return 0 end
    PNC.Registry.ForEach(function(record)
        if record.presenceState == Const.PRESENCE_ABSTRACT
            and Model.IsActive(record.travel)
        then
            Service.Advance(record, hour)
            if PNC.SpatialIndex and PNC.SpatialIndex.UpdateNPC then
                PNC.SpatialIndex.UpdateNPC(record)
            end
            count = count + 1
        end
    end)
    return count
end

function Service.GetProgress(recordOrID, atWorldHour)
    local record = resolveRecord(recordOrID)
    local journey = record and record.travel or nil
    if not journey then return nil end
    local projected = journey
    if record.presenceState ~= Const.PRESENCE_LIVE then
        projected = Projection.Project(
            journey,
            tonumber(atWorldHour) or worldHour()
        ) or journey
    end
    local total = math.max(0, tonumber(projected.distanceTotal) or 0)
    local travelled = math.max(
        0,
        math.min(total, tonumber(projected.distanceTravelled) or 0)
    )
    return {
        journeyId = projected.journeyId,
        npcId = record.id,
        state = projected.state,
        x = projected.x or record.x,
        y = projected.y or record.y,
        z = projected.z or record.z,
        percent = total <= 0 and 1 or travelled / total,
        distanceTotal = total,
        distanceTravelled = travelled,
        distanceRemaining = math.max(0, total - travelled),
        etaWorldHour = projected.etaWorldHour,
        remainingWorldHours = projected.etaWorldHour
            and math.max(
                0,
                projected.etaWorldHour
                    - (tonumber(atWorldHour) or worldHour())
            )
            or nil,
        presenceState = record.presenceState,
        controller = projected.controller,
        ownerMod = projected.ownerMod,
        ownerRef = projected.ownerRef,
        metadata = Model.CopyMetadata(projected.metadata),
    }
end

for _, eventName in pairs(EVENT_NAMES) do
    if LuaEventManager and LuaEventManager.AddEvent then
        pcall(LuaEventManager.AddEvent, eventName)
    end
end

return Service
