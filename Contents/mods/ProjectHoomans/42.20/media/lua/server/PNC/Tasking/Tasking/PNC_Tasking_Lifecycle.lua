if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Priority = PNC.TaskPriority
local Leases = PNC.TaskLeaseService
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local H = Tasking.Internal

function Tasking.Commands.Complete(leaseId, reason)
    local lease = Leases.Get(leaseId)
    if not lease then return false, "LEASE_NOT_FOUND" end
    local provider = Tasking.Providers[lease.sourceDomain]
    if provider and provider.Complete then provider.Complete(lease, reason) end
    return Leases.Release(leaseId, "complete")
end

function Tasking.Commands.CancelForNPC(npcId, reason)
    local lease = Leases.ForNPC(npcId)
    if not lease then return false, "LEASE_NOT_FOUND" end
    return H.StopLease(lease, reason or "cancelled")
end

function Tasking.Commands.SetPhase(npcId, phase)
    local lease = Leases.ForNPC(npcId)
    return lease and Leases.SetPhase(lease.leaseId, phase)
        or false, "LEASE_NOT_FOUND"
end

return Tasking

