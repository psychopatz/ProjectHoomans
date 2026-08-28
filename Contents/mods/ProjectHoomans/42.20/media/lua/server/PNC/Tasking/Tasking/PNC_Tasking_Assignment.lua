if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Priority = PNC.TaskPriority
local Leases = PNC.TaskLeaseService
local H = Tasking.Internal

function H.ReconcileCurrentLease(npcId)
    local current = Leases.ForNPC(npcId)
    if not current then return nil, true end
    local provider = Tasking.Providers[current.sourceDomain]
    local canContinue = false
    if provider and provider.CanContinue then
        local callbackOK, callbackResult = H.SafeCall(
            "provider_can_continue", provider.CanContinue, {
                npcId = current.npcId, leaseId = current.leaseId,
                domain = current.sourceDomain,
            }, current)
        canContinue = callbackOK and callbackResult == true
    end
    if canContinue then return current, true end
    local stopped, stopReason = H.StopLease(current, "task_invalidated")
    if not stopped then return current, false, stopReason end
    return nil, true
end

function H.Preempt(record, current, winner)
    if current then
        local allowed, reason = Priority.CanPreempt(current, winner)
        if not allowed then
            return false, current.taskId, false, reason, "not_allowed"
        end
        local stopped, stopReason = H.StopLease(current, "preempted")
        if not stopped then
            return false, current.taskId, false, stopReason, "cleanup"
        end
        return true, current.taskId, true
    end
    local external = H.ExternalCurrent(record)
    if not external then return true, nil, false end
    local allowed, reason = Priority.CanPreempt(external, winner)
    if not allowed then
        return false, external.taskId, false, reason, "not_allowed"
    end
    local releaseOK, released, releaseReason = H.SafeCall(
        "work_preemption", PNC.WorkService and PNC.WorkService.Commands
            and PNC.WorkService.Commands.ReleaseWorker, {
                npcId = record.id, domain = "work",
            }, record.id, "task_preempted")
    if not releaseOK or not released then
        return false, external.taskId, false,
            releaseReason or "PREEMPTION_FAILED", "cleanup"
    end
    return true, external.taskId, true
end

local function rollback(winner, assignment, reason, lease)
    local provider = Tasking.Providers[winner.sourceDomain]
    if provider and provider.RollbackAssignment then
        local rollbackOK, rollbackResult = H.SafeCall(
            "provider_rollback", provider.RollbackAssignment, {
                npcId = winner.npcId,
                leaseId = lease and lease.leaseId or nil,
                domain = winner.sourceDomain,
            }, winner, assignment, reason)
        if rollbackOK and rollbackResult ~= false and lease then
            lease.reservationId = nil
        end
        return
    end
    if assignment and assignment.reservationId
        and PNC.FacilityReservations
        and PNC.FacilityReservations.Release
    then
        H.SafeCall("reservation_rollback", PNC.FacilityReservations.Release,
            { npcId = winner.npcId, domain = winner.sourceDomain },
            assignment.reservationId, reason)
    end
end

function H.Assign(winner)
    local provider = Tasking.Providers[winner.sourceDomain]
    if not provider then return false, "TASK_PROVIDER_NOT_FOUND" end
    local assignOK, assignment, reason = H.SafeCall("provider_assign",
        provider.Assign, { npcId = winner.npcId, domain = winner.sourceDomain },
        winner)
    if not assignOK then reason = reason or "ASSIGN_CALLBACK_FAILED" end
    if not assignment then return false, reason or "ASSIGN_FAILED" end
    local lease, leaseReason = Leases.Create(winner, assignment)
    if not lease then
        rollback(winner, assignment, "lease_creation_failed")
        return false, leaseReason
    end
    local started = true
    local startReason
    if provider.Start then
        local startOK, startResult, callbackReason = H.SafeCall(
            "provider_start", provider.Start, {
                npcId = lease.npcId, leaseId = lease.leaseId,
                domain = lease.sourceDomain,
            }, lease, assignment)
        started, startReason = startOK and startResult == true, callbackReason
        if not startOK then startReason = startReason or "START_CALLBACK_FAILED" end
    end
    if not started then
        rollback(winner, assignment, "start_failed", lease)
        local released, releaseReason = Leases.Release(lease.leaseId,
            "start_failed")
        if not released then startReason = releaseReason end
        return false, startReason or "START_FAILED"
    end
    return true, lease
end

return Tasking
