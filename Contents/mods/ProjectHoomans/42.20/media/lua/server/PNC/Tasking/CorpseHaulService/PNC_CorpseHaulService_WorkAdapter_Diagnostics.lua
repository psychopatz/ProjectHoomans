-- Bounded diagnostics for corpse haul work operations.
--
-- This provider owns durable failure metadata and throttled console output.
-- Work execution keeps the diagnostic contract through Service.Internal.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local WorkRepository = PNC.WorkRepository

local function operationDiagnostic(order, task, record, stage, reason, kind)
    if not order then return end
    local now = Core.Now()
    local normalizedStage = tostring(stage or "UNKNOWN")
    local normalizedReason = tostring(reason or "UNKNOWN")
    local key = normalizedStage .. ":" .. normalizedReason
    local shouldLog = true
    local stateChanged = order.lastDiagnosticReason ~= normalizedReason
        or order.lastDiagnosticStage ~= normalizedStage
    local failureChanged = tostring(kind or "FAIL") == "FAIL"
        and (order.lastExecutionFailureReason ~= normalizedReason
            or order.lastExecutionFailurePhase
                ~= tostring(order.phase or ""))
    local previousKey = task and task.lastDiagnosticKey
        or order.lastDiagnosticKey
    local previousAt = task and tonumber(task.lastDiagnosticAt)
        or tonumber(order.lastDiagnosticLogAt)
    local interval = kind == "WAIT"
        and (tonumber(Service.CORPSE_HAUL_WORLD_WAIT_DIAGNOSTIC_INTERVAL_MS)
            or 30000)
        or tonumber(Service.CORPSE_HAUL_DIAGNOSTIC_INTERVAL_MS) or 2000
    if previousKey == key and previousAt
        and now - previousAt < interval
    then
        shouldLog = false
    end
    if shouldLog and task then
        task.lastDiagnosticKey = key
        task.lastDiagnosticAt = now
    end
    if shouldLog then
        order.lastDiagnosticKey = key
        order.lastDiagnosticLogAt = now
    end
    record = record or Registry and Registry.Get
        and Registry.Get(order.workerId) or nil
    if stateChanged then
        order.lastDiagnosticReason = normalizedReason
        order.lastDiagnosticStage = normalizedStage
        order.lastDiagnosticAt = now
    end
    if failureChanged then
        order.lastExecutionFailureReason = normalizedReason
        order.lastExecutionFailurePhase = tostring(order.phase or "")
        order.lastExecutionFailureAt = now
    end
    if (stateChanged or failureChanged or shouldLog)
        and WorkRepository and WorkRepository.MarkDirty
    then
        WorkRepository.MarkDirty()
    end
    if shouldLog and Core.Log then
        local payload = order.payload or {}
        local live = record and Registry and Registry.GetLiveZombie
            and Registry.GetLiveZombie(record.id) or nil
        local x = tonumber(live and live.getX and live:getX())
            or tonumber(record and record.x) or "?"
        local y = tonumber(live and live.getY and live:getY())
            or tonumber(record and record.y) or "?"
        local z = tonumber(live and live.getZ and live:getZ())
            or tonumber(record and record.z) or "?"
        Core.Log(kind == "WAIT" and "INFO" or "WARN",
            "corpse_haul_diagnostic stage="
            .. normalizedStage .. " kind=" .. tostring(kind or "FAIL")
            .. " order=" .. tostring(order.id or "unknown")
            .. " npc=" .. tostring(order.workerId or record and record.id
                or "unknown")
            .. " phase=" .. tostring(order.phase or "")
            .. " status=" .. tostring(order.status or "")
            .. " reason=" .. normalizedReason
            .. " pos=" .. tostring(x) .. "," .. tostring(y) .. ","
            .. tostring(z)
            .. " source=" .. tostring(payload.sourceX or "?") .. ","
            .. tostring(payload.sourceY or "?") .. ","
            .. tostring(payload.sourceZ or "?")
            .. " token=" .. tostring(payload.haulToken or "?")
            .. " death=" .. tostring(payload.deathMarkerId
                or payload.corpseId or "?"))
    end
end

local function operationFailure(order, task, record, stage, reason)
    operationDiagnostic(order, task, record, stage, reason, "FAIL")
    return false, reason
end

Internal.operationDiagnostic = operationDiagnostic
Internal.operationFailure = operationFailure

return Service
