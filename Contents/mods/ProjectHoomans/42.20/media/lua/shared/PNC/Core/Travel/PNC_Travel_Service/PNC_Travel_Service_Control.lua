local Service = PNC.Travel.Service
local Internal = Service.Internal
local Core = PNC.Core
local Const = PNC.Const
local Model = PNC.Travel.Model
local Projection = PNC.Travel.Projection

local function resetMovementForTravel(record, reason)
    local registry = PNC.Registry
    local pathService = PNC.PathService
    local zombie
    if registry and registry.GetLiveZombie then
        zombie = registry.GetLiveZombie(record and record.id)
    end
    if pathService and pathService.Commands
        and pathService.Commands.Reset
    then
        pathService.Commands.Reset(record, zombie, reason or "travel_started")
        return true
    end
    if pathService and pathService.Reset then
        pathService.Reset(zombie, record)
        return true
    end
    if record and record.runtime then
        record.runtime.moveIntent = nil
        record.runtime.pathing = nil
        record.runtime.localNavigation = nil
    end
    return false
end

function Service.Start(recordOrID, request)
    local record = Internal.ResolveRecord(recordOrID)
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
    local nowHour = Internal.WorldHour()
    local journey = Model.New(record, request, nowHour)
    -- Travel is a movement-owner boundary. A completed work order can leave a
    -- native path2/WalkTowardState pair alive for one deferred engine update;
    -- clear that old owner before publishing the new durable travel order.
    resetMovementForTravel(record, "travel_started")
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
    Internal.MarkChanged(record, "travel", "travel_started", true)
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
        journey.arrivedWorldHour = Internal.WorldHour()
        Service.EnsureArrivalHandled(
            record,
            reason or "arrived",
            false
        )
    elseif state == "paused" then
        journey.pausedWorldHour = Internal.WorldHour()
    end
    Internal.MarkChanged(record, "travel", "travel_state", false)
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
    local record = Internal.ResolveRecord(recordOrID)
    if not record or not Model.IsActive(record.travel) then
        return false, "journey_inactive"
    end
    Service.Advance(record, Internal.WorldHour())
    return Service.SetState(record, "paused", reason or "paused")
end

function Service.Resume(recordOrID, reason)
    local record = Internal.ResolveRecord(recordOrID)
    local journey = record and record.travel or nil
    if not journey or journey.state ~= "paused" then
        return false, "journey_not_paused"
    end
    journey.lastAdvancedWorldHour = Internal.WorldHour()
    return Service.SetState(record, "en_route", reason or "resumed")
end

function Service.Cancel(recordOrID, reason)
    local record = Internal.ResolveRecord(recordOrID)
    if not record or not Model.IsActive(record.travel) then
        return false, "journey_inactive"
    end
    Service.Advance(record, Internal.WorldHour())
    return Service.SetState(record, "cancelled", reason or "cancelled")
end

function Service.Retarget(recordOrID, request)
    local record = Internal.ResolveRecord(recordOrID)
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
        if body then Service.SyncLivePosition(record, body, Internal.WorldHour()) end
    else
        Service.Advance(record, Internal.WorldHour())
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
    local replacement = Model.New(record, request, Internal.WorldHour())
    replacement.routeVersion = (tonumber(previous.routeVersion) or 0) + 1
    replacement.revision = (tonumber(previous.revision) or 0) + 1
    replacement.lastStateReason = "retargeted"
    record.travel = replacement
    record.orderSpec = {
        kind = Const.ORDER_TRAVEL or "travel",
        journeyId = replacement.journeyId,
    }
    Internal.MarkChanged(record, "travel", "travel_retargeted", true)
    Service.Emit("state_changed", record, replacement, "retargeted")
    return replacement
end
