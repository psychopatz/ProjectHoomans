-- Lease reservation release and terminal cleanup.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Leases = PNC.TaskLeaseService
local Internal = Leases.Internal

function Leases.Release(id, reason)
    local lease = Leases.Get(id)
    if not lease then return false, "LEASE_NOT_FOUND" end
    if lease.reservationId and PNC.FacilityReservations then
        local releaseReason = reason == "complete"
            and "complete" or reason or "task_released"
        local taskInternal = PNC.Tasking and PNC.Tasking.Internal
        local ok
        local released
        local callbackReason
        if taskInternal and type(taskInternal.SafeCall) == "function" then
            ok, released, callbackReason = taskInternal.SafeCall(
                "lease_reservation_release",
                PNC.FacilityReservations.Release,
                {
                    npcId = lease.npcId,
                    leaseId = lease.leaseId,
                    domain = lease.sourceDomain,
                },
                lease.reservationId,
                releaseReason
            )
        else
            released, callbackReason = PNC.FacilityReservations.Release(
                lease.reservationId,
                releaseReason
            )
            ok = true
        end
        -- Reservation cleanup is deliberately idempotent at the lease
        -- boundary.  A facility can already have released its reservation
        -- during teardown, but the task lease still owns the cleanup step.
        -- Treat that specific result as success so the lease can be removed;
        -- preserve failures for every other rejection.
        if ok and released == false
            and tostring(callbackReason or "") == "RESERVATION_NOT_FOUND"
        then
            lease.reservationId = nil
            released = true
        end
        if not ok or released == false then
            if ok and taskInternal and taskInternal.RecordFailure
            then
                taskInternal.RecordFailure(
                    "lease_reservation_release", {
                        npcId = lease.npcId, leaseId = lease.leaseId,
                        domain = lease.sourceDomain,
                    }, callbackReason or "RESERVATION_RELEASE_REJECTED")
            end
            return false, "RESERVATION_RELEASE_FAILED"
        end
        lease.reservationId = nil
    end
    Leases.ByID[lease.leaseId], Leases.ByNPC[lease.npcId] = nil, nil
    Internal.RemoveActive(lease.leaseId)
    lease.phase, lease.releaseReason = "DONE", tostring(reason or "released")
    lease.revision = lease.revision + 1
    Internal.Emit("TASK_LEASE_RELEASED", lease, { cause = lease.releaseReason })
    return true, lease
end
