local Presence = PNC.Presence
local Internal = Presence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Admission = PNC.PresenceAdmission

Internal.MaterializationBudget = Internal.MaterializationBudget or {
    tickAt = nil,
    count = 0,
}

function Internal.ResolveNetwork()
    if not Internal.Network then
        Internal.Network = PNC.Network
    end
    return Internal.Network
end

function Presence.BeginServerTick(now)
    local budget = Internal.MaterializationBudget
    budget.tickAt = tonumber(now) or Core.Now()
    budget.count = 0
end

function Internal.ConsumeMaterializationBudget(record, reason, nearest)
    local now
    local maximum
    local allowed
    local admissionReason
    local budget = Internal.MaterializationBudget
    if tostring(reason or "") ~= "range_enter" then return true end
    now = Core.Now()
    if budget.tickAt ~= now then
        budget.tickAt = now
        budget.count = 0
    end
    maximum = math.max(
        1,
        math.floor(tonumber(Const.MATERIALIZE_MAX_PER_TICK) or 2)
    )
    if Admission and Admission.Evaluate then
        allowed, admissionReason = Admission.Evaluate(record, nearest)
        if allowed == false then
            record.runtime = record.runtime or {}
            record.runtime.materializeAdmissionReason = admissionReason
            record.runtime.materializeRetryAt = now
                + (tonumber(Const.LIVE_BODY_ADMISSION_RETRY_MS) or 1000)
            return false
        end
    end
    if budget.count < maximum then
        budget.count = budget.count + 1
        record.runtime = record.runtime or {}
        record.runtime.materializeAdmissionReason = nil
        return true
    end
    record.runtime = record.runtime or {}
    record.runtime.forcePresenceCheck = true
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, "presence", now)
    end
    return false
end
