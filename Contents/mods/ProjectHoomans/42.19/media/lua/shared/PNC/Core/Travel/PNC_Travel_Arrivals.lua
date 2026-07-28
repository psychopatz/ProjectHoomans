-- Serializable journey-arrival actions and their authority-side handlers.
-- Cross-mod callers store only a handler id plus data on the journey; runtime
-- functions stay in this registry and therefore never enter persistence or
-- multiplayer payloads.

PNC = PNC or {}
PNC.Travel = PNC.Travel or {}
PNC.Travel.Arrivals = PNC.Travel.Arrivals or {}

local Arrivals = PNC.Travel.Arrivals
local Const = PNC.Const
local Core = PNC.Core

Arrivals.Handlers = Arrivals.Handlers or {}

local function copySerializable(value, depth, budget)
    local valueType = type(value)
    local output
    local key
    local copied
    if valueType == "nil"
        or valueType == "boolean"
        or valueType == "number"
        or valueType == "string"
    then
        return value
    end
    if valueType ~= "table"
        or depth >= (tonumber(Const.TRAVEL_METADATA_MAX_DEPTH) or 3)
        or budget.count >= (
            tonumber(Const.TRAVEL_METADATA_MAX_ENTRIES) or 64
        )
    then
        return nil
    end
    output = {}
    for key, value in pairs(value) do
        if budget.count >= (
            tonumber(Const.TRAVEL_METADATA_MAX_ENTRIES) or 64
        ) then
            break
        end
        if type(key) == "string" or type(key) == "number" then
            copied = copySerializable(value, depth + 1, budget)
            if copied ~= nil then
                output[key] = copied
                budget.count = budget.count + 1
            end
        end
    end
    return output
end

function Arrivals.Normalize(action)
    local normalized
    local actionType
    if action == false then
        return { type = "none" }
    end
    if type(action) == "string" then
        actionType = action
        normalized = {}
    elseif type(action) == "table" then
        normalized = copySerializable(action, 0, { count = 0 }) or {}
        actionType = normalized.type
            or normalized.kind
            or normalized.id
    else
        normalized = {}
    end
    actionType = tostring(
        actionType
            or Const.TRAVEL_DEFAULT_ARRIVAL_ACTION
            or "roam"
    )
    if actionType == "" then
        actionType = tostring(
            Const.TRAVEL_DEFAULT_ARRIVAL_ACTION or "roam"
        )
    end
    normalized.type = actionType
    return normalized
end

function Arrivals.RegisterHandler(id, handler)
    id = tostring(id or "")
    if id == "" or type(handler) ~= "function" then
        return false
    end
    Arrivals.Handlers[id] = handler
    return true
end

function Arrivals.UnregisterHandler(id)
    id = tostring(id or "")
    if id == "roam" or id == "none"
        or id == ""
        or Arrivals.Handlers[id] == nil
    then
        return false
    end
    Arrivals.Handlers[id] = nil
    return true
end

local function setFallbackOrder(record, order)
    record.runtime = record.runtime or {}
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        PNC.OrderSystem.SetOrder(record, order)
    else
        record.orderSpec = order
        record.runtime.target = nil
        record.runtime.roaming = nil
        record.nextThinkAt = Core.Now()
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "order")
        end
    end
end

local function roamOnArrival(record, journey, action)
    local destination = journey and journey.destination or {}
    setFallbackOrder(record, {
        kind = Const.ORDER_ROAM or "roam",
        roamMode = tostring(
            action.roamMode or Const.ROAM_MODE_AREA or "area"
        ),
        x = tonumber(action.x)
            or tonumber(destination.x)
            or record.x,
        y = tonumber(action.y)
            or tonumber(destination.y)
            or record.y,
        z = tonumber(action.z)
            or tonumber(destination.z)
            or record.z,
        radius = math.max(
            0.5,
            tonumber(action.radius)
                or tonumber(Const.ROAM_DEFAULT_RADIUS)
                or 6
        ),
        targetRadius = action.targetRadius,
        reachedDistance = action.reachedDistance,
        moveMode = action.moveMode,
        pauseMinMs = action.pauseMinMs,
        pauseMaxMs = action.pauseMaxMs,
    })
    return true, "roaming"
end

local function noActionOnArrival()
    return true, "none"
end

function Arrivals.Dispatch(record, journey, reason)
    local action
    local actionType
    local handler
    local ok
    local handled
    local handlerReason
    local requestedType
    if not record or not journey or journey.state ~= "arrived" then
        return false, "not_arrived"
    end
    if journey.arrivalHandled == true then
        return true, journey.arrivalHandledReason or "already_handled"
    end
    action = Arrivals.Normalize(journey.arrivalAction)
    journey.arrivalAction = action
    actionType = tostring(action.type or "roam")
    requestedType = actionType
    handler = Arrivals.Handlers[actionType]
    if not handler then
        actionType = tostring(
            Const.TRAVEL_DEFAULT_ARRIVAL_ACTION or "roam"
        )
        handler = Arrivals.Handlers[actionType]
        handlerReason = "handler_missing:" .. requestedType
    end
    if not handler then
        return false, handlerReason or "arrival_handler_missing"
    end

    -- Set the guard before invoking extension code so a handler that wakes or
    -- reschedules the record cannot dispatch the same arrival recursively.
    journey.arrivalHandled = true
    ok, handled, reason = pcall(
        handler,
        record,
        journey,
        action,
        reason
    )
    if not ok or handled == false then
        journey.arrivalHandled = false
        if requestedType ~= (
            Const.TRAVEL_DEFAULT_ARRIVAL_ACTION or "roam"
        ) then
            actionType = tostring(
                Const.TRAVEL_DEFAULT_ARRIVAL_ACTION or "roam"
            )
            handler = Arrivals.Handlers[actionType]
            if handler then
                journey.arrivalHandled = true
                ok, handled, reason = pcall(
                    handler,
                    record,
                    journey,
                    Arrivals.Normalize(nil),
                    "fallback:" .. requestedType
                )
            end
        end
    end
    if not ok or handled == false then
        journey.arrivalHandled = false
        if Core and Core.LogWarn then
            Core.LogWarn(
                "PNC arrival action failed npc="
                    .. tostring(record.id)
                    .. " type="
                    .. tostring(requestedType)
                    .. " error="
                    .. tostring(reason)
            )
        end
        return false, tostring(reason or "arrival_handler_failed")
    end

    journey.arrivalHandledBy = actionType
    journey.arrivalHandledReason = handlerReason
        or tostring(reason or "handled")
    record.runtime = record.runtime or {}
    record.runtime.travelArrival = {
        journeyId = journey.journeyId,
        requestedType = requestedType,
        handledBy = actionType,
        reason = journey.arrivalHandledReason,
        at = Core.Now(),
    }
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "travel_arrival")
    end
    return true, journey.arrivalHandledReason
end

Arrivals.RegisterHandler("roam", roamOnArrival)
Arrivals.RegisterHandler("none", noActionOnArrival)

return Arrivals
