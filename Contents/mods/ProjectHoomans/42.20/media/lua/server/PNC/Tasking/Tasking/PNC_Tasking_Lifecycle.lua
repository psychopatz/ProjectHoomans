if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Priority = PNC.TaskPriority
local Leases = PNC.TaskLeaseService
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local H = Tasking.Internal

local function requestReevaluation(npcId, reason)
    local events = Tasking.Events
    if not events or type(events.Emit) ~= "function" then
        return false, "TASKING_EVENTS_UNAVAILABLE"
    end
    events.Emit("TASK_CANCELLATION_COMPLETED", {
        npcId = tostring(npcId or ""),
        source = "Tasking.Cancellation",
        cause = tostring(reason or "cancelled"),
    }, { immediate = true })
    return true, "TASK_REEVALUATION_REQUESTED"
end

function Tasking.Commands.Complete(leaseId, reason)
    local lease = Leases.Get(leaseId)
    if not lease then return false, "LEASE_NOT_FOUND" end
    local provider = Tasking.Providers[lease.sourceDomain]
    if provider and provider.Complete then
        local ok, completed, callbackReason = H.SafeCall(
            "provider_complete", provider.Complete, {
                npcId = lease.npcId, leaseId = lease.leaseId,
                domain = lease.sourceDomain,
            }, lease, reason)
        if not ok or completed == false then
            return false, callbackReason or "TASK_COMPLETE_CALLBACK_FAILED"
        end
    end
    return Leases.Release(leaseId, "complete")
end

function Tasking.Commands.CancelForNPC(npcId, reason)
    local lease = Leases.ForNPC(npcId)
    if not lease then return false, "LEASE_NOT_FOUND" end
    return H.StopLease(lease, reason or "cancelled")
end

function Tasking.Commands.CancelLease(leaseId, reason)
    local lease = Leases.Get(leaseId)
    if not lease then return false, "LEASE_NOT_FOUND" end
    return H.StopLease(lease, reason or "cancelled")
end

-- Player cancellation releases a transient lease outside the normal task
-- pump. Wake that NPC immediately so the brain cannot remain on the old
-- decision until an unrelated needs or world event arrives.
function Tasking.Commands.ReevaluateAfterCancellation(npcId, reason)
    return requestReevaluation(npcId, reason)
end

function Tasking.Commands.SetPhase(npcId, phase)
    local lease = Leases.ForNPC(npcId)
    return lease and Leases.SetPhase(lease.leaseId, phase)
        or false, "LEASE_NOT_FOUND"
end

return Tasking
