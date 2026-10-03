-- Lease phase normalization and transition context.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Leases = PNC.TaskLeaseService
local Internal = Leases.Internal

local function normalizePhase(phase)
    phase = string.upper(tostring(phase or ""))
    return Leases.PHASE_ALIASES[phase] or phase
end

local function emit(eventType, lease, details)
    local events = PNC.Tasking and PNC.Tasking.Events
    if not events or type(events.Emit) ~= "function" then return end
    details = details or {}
    details.npcId = lease.npcId
    details.entityId = lease.leaseId
    details.source = "TaskLeaseService"
    details.revision = lease.revision
    details.payload = details.payload or { taskId = lease.taskId,
        sourceDomain = lease.sourceDomain, phase = lease.phase }
    events.Emit(eventType, details, { enqueue = false })
end

local function transition(lease, phase, reason)
    phase = normalizePhase(phase)
    if not Leases.PHASES[phase] then
        return false, "INVALID_TASK_PHASE"
    end
    local allowed = Leases.TRANSITIONS[lease.phase]
    if not allowed or not allowed[phase] then
        if PNC.Tasking and PNC.Tasking.Diagnostics then
            PNC.Tasking.Diagnostics.counters.leaseTransitionFailures =
                PNC.Tasking.Diagnostics.counters.leaseTransitionFailures + 1
        end
        return false, "INVALID_TASK_PHASE_TRANSITION"
    end
    if lease.phase == phase then return true, lease end
    local previous = lease.phase
    lease.phase = phase
    lease.revision = lease.revision + 1
    emit("TASK_LEASE_PHASE_CHANGED", lease, {
        cause = reason or "phase_changed",
        payload = { from = previous, to = phase,
            taskId = lease.taskId, sourceDomain = lease.sourceDomain },
    })
    return true, lease
end

function Leases.SetPhase(id, phase)
    local lease = Leases.Get(id)
    if not lease then return false, "LEASE_NOT_FOUND" end
    return transition(lease, phase, "provider_phase_update")
end

Internal.NormalizePhase = normalizePhase
Internal.Emit = emit
Internal.Transition = transition
