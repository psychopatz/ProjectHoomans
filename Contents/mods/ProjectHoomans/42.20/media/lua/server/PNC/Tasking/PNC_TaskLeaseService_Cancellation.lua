-- Lease cancellation policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Leases = PNC.TaskLeaseService
local Internal = Leases.Internal

function Leases.RequestCancellation(id, reason)
    local lease = Leases.Get(id)
    if not lease then return false, "LEASE_NOT_FOUND" end
    local nonInterruptible = PNC.TaskRequestDefinitions
        and PNC.TaskRequestDefinitions.NON_INTERRUPTIBLE_PHASE or {}
    local atomic = nonInterruptible[lease.phase]
    if lease.cancellationRequested == true then
        if atomic then
            lease.cancellationDeferred = true
            return true, "CANCELLATION_DEFERRED"
        end
        lease.cancellationDeferred = false
        if lease.phase ~= "CANCELLING" then
            return Internal.Transition(lease, "CANCELLING", "cancellation_requested")
        end
        return true, "CANCELLING"
    end
    lease.cancellationRequested = true
    lease.cancellationReason = tostring(reason or "cancelled")
    lease.revision = lease.revision + 1
    lease.cancellationDeferred = atomic == true
    if not atomic then
        local changed, transitionReason = Internal.Transition(lease, "CANCELLING",
            "cancellation_requested")
        if not changed then return false, transitionReason end
    end
    return true, atomic and "CANCELLATION_DEFERRED" or "CANCELLING"
end
