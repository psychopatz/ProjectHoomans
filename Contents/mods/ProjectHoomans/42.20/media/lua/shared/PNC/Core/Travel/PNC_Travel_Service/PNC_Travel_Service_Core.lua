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
local Internal = Service.Internal
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
    local attempts
    local retryAt
    if not journey or journey.state ~= "arrived" then
        return false, "not_arrived"
    end
    if not Arrivals or not Arrivals.Dispatch then
        return false, "arrival_dispatch_unavailable"
    end
    if journey.arrivalHandled ~= true
        and journey.arrivalFailedReason ~= nil
    then
        -- A failed arrival action is retried a bounded number of times. Without
        -- this the projection lane re-dispatched it on every advance.
        attempts = tonumber(journey.arrivalAttempts) or 0
        retryAt = tonumber(journey.arrivalRetryAt) or 0
        if attempts >= (tonumber(Const.TRAVEL_ARRIVAL_MAX_ATTEMPTS) or 3) then
            return false, journey.arrivalFailedReason
        end
        if Core and Core.Now and Core.Now() < retryAt then
            return false, "arrival_retry_wait"
        end
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

-- One bounded diagnostic per escalation or failure transition. Nothing here
-- runs per tick; every caller is cooldown-gated.
function Internal.LogTravelDiag(record, journey, event, reason)
    local target
    local targetReason
    local occupancy = PNC.TraversalQuery
    local remaining
    if not record or not journey then return end
    if not (Core and Core.LogWarn) then return end
    target = Service.GetCurrentTarget and Service.GetCurrentTarget(record) or nil
    if target and occupancy and occupancy.GetOccupancyReason then
        targetReason = occupancy.GetOccupancyReason(
            target.x,
            target.y,
            target.z
        )
    end
    remaining = math.max(
        0,
        (tonumber(journey.distanceTotal) or 0)
            - (tonumber(journey.distanceTravelled) or 0)
    )
    Core.LogWarn(
        "travel_" .. tostring(event)
            .. " npc=" .. tostring(record.id)
            .. " journey=" .. tostring(journey.journeyId)
            .. " ownerRef=" .. tostring(journey.ownerRef)
            .. " state=" .. tostring(journey.state)
            .. " controller=" .. tostring(journey.controller)
            .. " remaining=" .. tostring(math.floor(remaining))
            .. " recoveries=" .. tostring(journey.liveRecoveryCount or 0)
            .. " escalations=" .. tostring(journey.liveEscalationCount or 0)
            .. " playerDistSq="
            .. tostring(record.runtime and record.runtime.nearestPlayerDistSq)
            .. " target=" .. (target
                and (tostring(math.floor(tonumber(target.x) or 0)) .. ","
                    .. tostring(math.floor(tonumber(target.y) or 0)))
                or "nil")
            .. " targetOccupancy=" .. tostring(targetReason or "clear")
            .. " reason=" .. tostring(reason)
    )
end

-- The requester that owns the journey reacts to a failure it did not cause.
-- Resolved through ownerRef so Travel keeps no dependency on the duty
-- services that use it.
local OWNER_NOTIFIERS = {
    colony_return_home = function(record, journey, reason)
        local home = PNC.HomeDutyService
        if home and type(home.OnTravelFailed) == "function" then
            return home.OnTravelFailed(record, reason, journey)
        end
        return false
    end,
}

function Service.NotifyOwner(record, journey, reason)
    local notifier = OWNER_NOTIFIERS[tostring(journey.ownerRef or "")]
    if not notifier then return false end
    return notifier(record, journey, reason) == true
end

-- Terminal journey state. A journey must never stay active without a lane that
-- can advance it, so every escalation path ends here.
function Service.FailJourney(recordOrID, reason, cause)
    local record = resolveRecord(recordOrID)
    local journey = record and record.travel or nil
    local order
    if not journey then return false, "journey_missing" end
    reason = tostring(reason or "failed")
    if Model.IsActive(journey) then
        Service.SetState(record, "cancelled", reason)
    end
    journey.failureReason = reason
    journey.failureCause = cause and tostring(cause) or nil
    journey.handoffForced = nil
    journey.lastStateReason = reason
    -- Release the travel order so the behavior stops ticking a terminal
    -- journey. Normalize(nil, ...) resolves the record's deterministic
    -- fallback order, and the owner decides whether to retry.
    order = record.orderSpec
    if order and tostring(order.kind or "")
        == tostring(Const.ORDER_TRAVEL or "travel")
        and tostring(order.journeyId or "")
            == tostring(journey.journeyId or "")
    then
        if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
            PNC.OrderSystem.SetOrder(record, nil)
        else
            record.orderSpec = nil
        end
        record.nextThinkAt = Core.Now()
    end
    Internal.LogTravelDiag(record, journey, "journey_failed", reason)
    Service.NotifyOwner(record, journey, reason)
    return true, reason
end

-- Bounded watchdog for live journeys that lost their movement owner (order
-- replaced, lane vanished) or never made progress. Abstract journeys are
-- already swept by RefreshAbstractPositions.
function Service.AuditActiveLiveJourneys(nowMs, force)
    local interval = tonumber(Const.TRAVEL_JOURNEY_WATCHDOG_INTERVAL_MS)
        or 5000
    local timeoutMs = tonumber(Const.TRAVEL_JOURNEY_STALL_TIMEOUT_MS)
        or 45000
    local budget = tonumber(Const.TRAVEL_JOURNEY_WATCHDOG_MAX_PER_PASS) or 8
    local maxFailures = tonumber(Const.TRAVEL_JOURNEY_WATCHDOG_MAX_FAILURES)
        or 2
    local checked = 0
    local escalated = 0
    local lastProgress
    local owned
    local stalled
    nowMs = tonumber(nowMs) or (Core and Core.Now and Core.Now() or 0)
    if force ~= true
        and nowMs - (tonumber(Service.LastLiveJourneyAuditAt) or 0) < interval
    then
        return 0
    end
    Service.LastLiveJourneyAuditAt = nowMs
    if not PNC.Registry or not PNC.Registry.ForEach then return 0 end
    PNC.Registry.ForEach(function(record)
        if checked >= budget then return end
        local journey = record.travel
        if record.presenceState ~= Const.PRESENCE_LIVE
            or not Model.IsActive(journey)
            or journey.state ~= "en_route"
        then
            return
        end
        checked = checked + 1
        -- A journey that has never been ticked yet is not stalled: the
        -- creation stamp gives the movement lane a full grace window.
        lastProgress = tonumber(journey.liveLastProgressAt)
            or tonumber(journey.createdAtMs)
        owned = record.orderSpec
            and tostring(record.orderSpec.kind or "")
                == tostring(Const.ORDER_TRAVEL or "travel")
            and tostring(record.orderSpec.journeyId or "")
                == tostring(journey.journeyId or "")
        stalled = lastProgress == nil
            or (nowMs - lastProgress) >= timeoutMs
        if owned and not stalled then return end
        journey.watchdogFailures = (tonumber(journey.watchdogFailures) or 0) + 1
        record.runtime = record.runtime or {}
        record.runtime.forcePresenceCheck = true
        journey.handoffForced = true
        journey.handoffReason = owned and "stalled" or "owner_lost"
        Internal.LogTravelDiag(
            record,
            journey,
            owned and "watchdog_stall" or "watchdog_owner_lost",
            journey.handoffReason
        )
        if journey.watchdogFailures > maxFailures then
            Service.FailJourney(
                record,
                owned and "live_unreachable" or "owner_lost",
                "watchdog"
            )
        end
        escalated = escalated + 1
    end)
    return escalated
end

function Service.Get(recordOrID)
    local record = resolveRecord(recordOrID)
    return record and record.travel or nil
end

Internal.WorldHour = worldHour
Internal.ResolveRecord = resolveRecord
Internal.MarkDirty = markDirty
Internal.MarkChanged = markChanged
Internal.EventNames = EVENT_NAMES
