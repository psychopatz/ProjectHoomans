if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Priority = PNC.TaskPriority
local Leases = PNC.TaskLeaseService
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local H = Tasking.Internal

function H.Collect(record)
    local candidates = {}
    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("NPCDecisions.CandidateBuilds")
    end
    for domain, provider in pairs(Tasking.Providers) do
        local values = provider.GetCandidates(record.id)
        for _, value in ipairs(type(values) == "table" and values or {}) do
            local intent = PNC.TaskIntent.Normalize(value)
            if intent then
                local valid = provider.Validate(intent)
                if valid == true then candidates[#candidates + 1] = intent end
            end
        end
    end
    table.sort(candidates, function(a, b) return Priority.Compare(a, b) > 0 end)
    return candidates
end

function H.StopLease(lease, reason)
    local requested, state = Leases.RequestCancellation(lease.leaseId, reason)
    if not requested or state == "CANCELLATION_DEFERRED" then
        return requested, state
    end
    local provider = Tasking.Providers[lease.sourceDomain]
    if provider and provider.Cancel then provider.Cancel(lease, reason) end
    return Leases.Release(lease.leaseId, reason)
end

function H.ExternalCurrent(record)
    if record and record.runtime and record.runtime.workOrderId then
        return { taskId = "work:" .. tostring(record.runtime.workOrderId),
            precedence = "NORMAL_WORK", urgency = 0.5,
            phase = record.orderSpec and record.orderSpec.phase == "COMMIT"
                and "ATOMIC_COMMIT" or "WORKING" }
    end
    local kind = tostring(record and record.orderSpec
        and record.orderSpec.kind or "")
    local followKind = tostring(PNC.Const and PNC.Const.ORDER_FOLLOW or "follow")
    if kind ~= "" and kind ~= "colony_home"
        and kind ~= followKind
        and kind ~= tostring(PNC.Const and PNC.Const.ORDER_GUARD or "guard")
        and kind ~= "facility_activity"
    then
        return { taskId = "order:" .. kind, precedence = "FORCED_ORDER",
            urgency = 0.5, phase = "WORKING" }
    end
    return nil
end

function Tasking.Commands.Reevaluate(npcId, cause)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId)
    local diagnostics = { lastCause = tostring(cause or "manual"), candidates = {} }
    Tasking.Diagnostics.byNPC[tostring(npcId)] = diagnostics
    Tasking.Diagnostics.counters.reevaluations =
        Tasking.Diagnostics.counters.reevaluations + 1
    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("NPCDecisions.DecisionRuns")
    end
    if not record or record.alive == false then
        local existing = Leases.ForNPC(npcId)
        if existing then H.StopLease(existing, "npc_unavailable") end
        diagnostics.lastReason = "NPC_UNAVAILABLE"
        return false, diagnostics.lastReason
    end
    local current = Leases.ForNPC(npcId)
    local previousTaskId = current and current.taskId or nil
    if current then
        local provider = Tasking.Providers[current.sourceDomain]
        local canContinue = provider and provider.CanContinue
            and provider.CanContinue(current) == true
        if not canContinue then
            H.StopLease(current, "task_invalidated"); current = nil
        end
    end
    local candidates = H.Collect(record)
    Tasking.Diagnostics.counters.candidates =
        Tasking.Diagnostics.counters.candidates + #candidates
    for _, intent in ipairs(candidates) do
        diagnostics.candidates[#diagnostics.candidates + 1] = H.Copy(intent)
    end
    local winner = candidates[1]
    if not winner then diagnostics.lastReason = current and "CURRENT_ONLY" or "NO_CANDIDATE"; return current ~= nil end
    if current and current.taskId == winner.taskId then
        current.urgency, current.precedence = winner.urgency, winner.precedence
        if ScalingDiagnostics then
            ScalingDiagnostics.Increment(
                "NPCDecisions.SameTaskReselections"
            )
        end
        diagnostics.lastReason = "CURRENT_TASK_CONTINUES"; return true, current
    end
    if current then
        local allowed, reason = Priority.CanPreempt(current, winner)
        if not allowed then diagnostics.lastReason = reason; return true, current end
        H.StopLease(current, "preempted")
        Tasking.Diagnostics.counters.preemptions =
            Tasking.Diagnostics.counters.preemptions + 1
    else
        local external = H.ExternalCurrent(record)
        if external then
            previousTaskId = external.taskId
            local allowed, reason = Priority.CanPreempt(external, winner)
            if not allowed then diagnostics.lastReason = reason; return false, reason end
            local released = PNC.WorkService and PNC.WorkService.Commands
                and PNC.WorkService.Commands.ReleaseWorker
                and PNC.WorkService.Commands.ReleaseWorker(record.id,
                    "task_preempted")
            if not released then diagnostics.lastReason = "PREEMPTION_FAILED"; return false, diagnostics.lastReason end
            Tasking.Diagnostics.counters.preemptions =
                Tasking.Diagnostics.counters.preemptions + 1
        end
    end
    local provider = Tasking.Providers[winner.sourceDomain]
    local assignment, reason = provider.Assign(winner)
    if not assignment then diagnostics.lastReason = reason or "ASSIGN_FAILED"; return false, diagnostics.lastReason end
    local lease, leaseReason = Leases.Create(winner, assignment)
    if not lease then
        if provider.RollbackAssignment then
            provider.RollbackAssignment(winner, assignment,
                "lease_creation_failed")
        elseif assignment.reservationId and PNC.FacilityReservations then
            PNC.FacilityReservations.Release(assignment.reservationId,
                "lease_creation_failed")
        end
        diagnostics.lastReason = leaseReason; return false, leaseReason
    end
    local started, startReason = provider.Start(lease, assignment)
    if started ~= true then
        if provider.RollbackAssignment then
            provider.RollbackAssignment(winner, assignment, "start_failed")
            lease.reservationId = nil
        end
        Leases.Release(lease.leaseId, "start_failed")
        diagnostics.lastReason = startReason or "START_FAILED"
        return false, diagnostics.lastReason
    end
    diagnostics.lastReason, diagnostics.currentLeaseId = "ASSIGNED", lease.leaseId
    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("NPCDecisions.TaskAssignments")
        if previousTaskId and previousTaskId ~= winner.taskId then
            ScalingDiagnostics.Increment("NPCDecisions.TaskSwitches")
        end
    end
    return true, lease
end

return Tasking

