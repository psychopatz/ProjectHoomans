-- Shared work-location policy and runtime projection.
--
-- Home duty answers where an NPC is relative to their base. Work location
-- answers whether an active order is allowed to take that NPC into the
-- world. Keeping the two concepts separate prevents remote jobs from being
-- mistaken for failed home duty.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

local Service = PNC.WorkService
local Internal = Service.Internal
local Location = Service.Location or {}
Service.Location = Location

Location.START_HOME = "HOME"
Location.START_ANYWHERE = "ANYWHERE"
Location.EXECUTION_HOME = "HOME"
Location.EXECUTION_REMOTE = "REMOTE"
Location.RETURN_STAY = "STAY"
Location.RETURN_HOME = "HOME"
Location.STATE_HOME = "HOME"
Location.STATE_AWAY = "AWAY"
Location.STATE_AWAY_FOR_WORK = "AWAY_FOR_WORK"
Location.STATE_RETURNING_HOME = "RETURNING_HOME"
Location.STATE_UNKNOWN = "UNKNOWN"

local function normalizeStart(value, fallback)
    value = string.upper(tostring(value or ""))
    if value == Location.START_HOME or value == Location.START_ANYWHERE then
        return value
    end
    return fallback
end

local function normalizeExecution(value, fallback)
    value = string.upper(tostring(value or ""))
    if value == Location.EXECUTION_HOME or value == Location.EXECUTION_REMOTE then
        return value
    end
    return fallback
end

local function normalizeReturn(value, fallback)
    value = string.upper(tostring(value or ""))
    if value == Location.RETURN_HOME or value == Location.RETURN_STAY then
        return value
    end
    return fallback
end

function Location.Normalize(spec)
    spec = type(spec) == "table" and spec or {}
    local raw = type(spec.locationPolicy) == "table"
        and spec.locationPolicy or {}
    local start = normalizeStart(raw.start, Location.START_HOME)
    local execution = normalizeExecution(raw.execution,
        start == Location.START_HOME and Location.EXECUTION_HOME
            or Location.EXECUTION_REMOTE)
    local returnHome = normalizeReturn(raw.returnHome, Location.RETURN_HOME)

    return { start = start, execution = execution, returnHome = returnHome }
end

function Location.StartsAtHome(order)
    return Location.Normalize(order).start == Location.START_HOME
end

function Location.ExecutionIsRemote(order)
    return Location.Normalize(order).execution == Location.EXECUTION_REMOTE
end

function Location.ReturnsHome(order)
    return Location.Normalize(order).returnHome == Location.RETURN_HOME
end

local function atHome(record, baseId)
    return PNC.HomeDutyService and PNC.HomeDutyService.IsAtHome
        and PNC.HomeDutyService.IsAtHome(record, baseId) == true or false
end

function Location.Classify(record, order)
    if not record then return Location.STATE_UNKNOWN, false end
    local baseId = order and order.baseId or nil
    local home = atHome(record, baseId)
    local returning = PNC.HomeDutyService
        and PNC.HomeDutyService.IsReturningHome
        and PNC.HomeDutyService.IsReturningHome(record, baseId) == true
    if returning then return Location.STATE_RETURNING_HOME, home end
    if order and tostring(order.workerId or "") == tostring(record.id or "")
        and Location.ExecutionIsRemote(order)
    then
        return home and Location.STATE_HOME or Location.STATE_AWAY_FOR_WORK,
            home
    end
    return home and Location.STATE_HOME or Location.STATE_AWAY, home
end

function Location.Observe(record, order, at)
    if not record then return Location.STATE_UNKNOWN end
    at = tonumber(at) or (PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
    local state, home = Location.Classify(record, order)
    record.runtime = record.runtime or {}
    local previous = record.runtime.workLocation or {}
    local orderId = order and tostring(order.id or "") or nil
    local changed = tostring(previous.state or "") ~= state
        or tostring(previous.orderId or "") ~= tostring(orderId or "")
    record.runtime.workLocation = {
        state = state, orderId = orderId,
        operation = order and order.operation or nil,
        atHome = home == true, updatedAt = at,
    }
    if changed then
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "work_location")
        end
        local events = PNC.Tasking and PNC.Tasking.Events
        if events and type(events.Emit) == "function" then
            events.Emit("WORK_LOCATION_CHANGED", {
                npcId = record.id, source = "WorkService.Location",
                entityId = orderId,
                payload = { state = state, orderId = orderId,
                    operation = order and order.operation or nil },
            })
        end
    end
    return state
end

function Location.Clear(record, orderId)
    local runtime = record and record.runtime or nil
    local current = runtime and runtime.workLocation or nil
    if not current then return false end
    if orderId and tostring(current.orderId or "") ~= tostring(orderId) then
        return false
    end
    runtime.workLocation = nil
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "work_location_cleared")
    end
    return true
end

function Location.ReturnHomeAfterWork(record, order)
    if not record or not order or not Location.ExecutionIsRemote(order)
        or not Location.ReturnsHome(order)
    then return false end
    if record.runtime and record.runtime.workOrderId then return false end
    if not PNC.HomeDutyService or not PNC.HomeDutyService.SendHome
        or not PNC.HomeDutyService.IsAtHome
        or PNC.HomeDutyService.IsAtHome(record, order.baseId)
    then return false end
    local ok = PNC.HomeDutyService.SendHome(record, order.baseId,
        "work_completed")
    return ok == true
end

Internal.locationPolicy = Location.Normalize
Internal.startsAtHome = Location.StartsAtHome
Internal.returnsHome = Location.ReturnsHome
Internal.executionIsRemote = Location.ExecutionIsRemote
Internal.workLocationState = Location.Classify
Internal.observeWorkLocation = Location.Observe
Internal.clearWorkLocation = Location.Clear
Internal.returnHomeAfterWork = Location.ReturnHomeAfterWork

return Service
