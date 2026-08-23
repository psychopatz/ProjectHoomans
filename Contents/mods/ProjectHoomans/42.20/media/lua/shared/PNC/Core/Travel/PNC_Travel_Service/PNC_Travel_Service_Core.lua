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

Internal.WorldHour = worldHour
Internal.ResolveRecord = resolveRecord
Internal.MarkDirty = markDirty
Internal.MarkChanged = markChanged
Internal.EventNames = EVENT_NAMES
