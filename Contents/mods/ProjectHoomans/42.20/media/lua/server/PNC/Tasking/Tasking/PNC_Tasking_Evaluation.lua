if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Priority = PNC.TaskPriority
local Leases = PNC.TaskLeaseService
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local H = Tasking.Internal

function H.Collect(record)
    local candidates = {}
    local failures = {}
    local maximum = math.max(1, math.floor(tonumber(
        Tasking.MAX_CANDIDATES_PER_PROVIDER) or 64))
    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("NPCDecisions.CandidateBuilds")
    end
    for domain, provider in pairs(Tasking.Providers) do
        local context = { npcId = record.id, domain = domain }
        local ok, values, callbackError = H.SafeCall(
            "provider_get_candidates", provider.GetCandidates, context,
            record.id)
        if not ok then
            failures[#failures + 1] = { domain = domain,
                error = callbackError }
        end
        local providerCount = 0
        for _, value in ipairs(ok and type(values) == "table" and values
            or {}) do
            if providerCount >= maximum then
                Tasking.Diagnostics.counters.candidateTruncations =
                    Tasking.Diagnostics.counters.candidateTruncations + 1
                break
            end
            providerCount = providerCount + 1
            local intent = PNC.TaskIntent.Normalize(value)
            if intent then
                local validOK, valid = H.SafeCall("provider_validate",
                    provider.Validate, context, intent)
                if validOK and valid == true then
                    candidates[#candidates + 1] = intent
                elseif not validOK then
                    failures[#failures + 1] = { domain = domain,
                        error = "VALIDATE_CALLBACK_FAILED" }
                end
            end
        end
    end
    table.sort(candidates, function(a, b) return Priority.Compare(a, b) > 0 end)
    return candidates, failures
end

function H.StopLease(lease, reason)
    local requested, state = Leases.RequestCancellation(lease.leaseId, reason)
    if not requested or state == "CANCELLATION_DEFERRED" then
        return requested, state
    end
    local provider = Tasking.Providers[lease.sourceDomain]
    local providerOK, providerResult, providerReason = true, true, nil
    if provider and provider.Cancel then
        providerOK, providerResult, providerReason = H.SafeCall(
            "provider_cancel", provider.Cancel, {
                npcId = lease.npcId, leaseId = lease.leaseId,
                domain = lease.sourceDomain,
            }, lease, reason)
    end
    -- A provider can fail after setting the lease to CANCELLING. Give the
    -- facility owner one last chance to clear an activity that still points
    -- at this lease before releasing the lease itself.
    local cleanupOK = providerOK and providerResult ~= false
    if not cleanupOK
        and PNC.Registry and PNC.Registry.Get
        and PNC.FacilityJobs and PNC.FacilityJobs.Stop
    then
        local record = PNC.Registry.Get(lease.npcId)
        local activity = record and record.runtime
            and record.runtime.facilityActivity or nil
        if activity and tostring(activity.taskLeaseId or "")
            == tostring(lease.leaseId)
        then
            local fallbackOK, fallbackResult = H.SafeCall(
                "facility_cleanup_fallback", PNC.FacilityJobs.Stop, {
                    npcId = lease.npcId, leaseId = lease.leaseId,
                    domain = lease.sourceDomain,
                }, record, reason or "task_provider_cleanup")
            cleanupOK = fallbackOK and fallbackResult ~= false
        end
    end
    if not cleanupOK then
        return false, providerReason or "TASK_CLEANUP_FAILED"
    end
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
    local campKind = tostring(PNC.Const and PNC.Const.ORDER_CAMP or "camp")
    if kind ~= "" and kind ~= "colony_home"
        and kind ~= followKind
        and kind ~= campKind
        and kind ~= tostring(PNC.Const and PNC.Const.ORDER_GUARD or "guard")
        and kind ~= "facility_activity"
    then
        return { taskId = "order:" .. kind, precedence = "FORCED_ORDER",
            urgency = 0.5, phase = "WORKING" }
    end
    return nil
end

function Tasking.Commands.Reevaluate(npcId, cause, event)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId)
    local diagnostics = { lastCause = tostring(cause or "manual"), candidates = {} }
    if type(event) == "table" then
        diagnostics.eventId = event.id
        diagnostics.eventType = event.type
        diagnostics.eventSource = event.source
        diagnostics.eventRevision = event.revision
        diagnostics.eventCauses = event.causes
    end
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
    local current, currentOK, currentReason = H.ReconcileCurrentLease(npcId)
    if not currentOK then
        diagnostics.lastReason = currentReason or "TASK_CLEANUP_FAILED"
        return false, diagnostics.lastReason
    end
    local candidates, providerFailures = H.Collect(record)
    Tasking.Diagnostics.counters.candidates =
        Tasking.Diagnostics.counters.candidates + #candidates
    diagnostics.providerFailures = providerFailures
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
    local previousTaskId
    local preemptOK, previous, didPreempt, preemptReason, preemptFailure = H.Preempt(
        record, current, winner)
    previousTaskId = previous
    if not preemptOK then
        diagnostics.lastReason = preemptReason
        if current and preemptFailure == "not_allowed" then
            return true, current
        end
        return false, diagnostics.lastReason
    end
    if didPreempt then
        Tasking.Diagnostics.counters.preemptions =
            Tasking.Diagnostics.counters.preemptions + 1
    end
    local assigned, leaseOrReason = H.Assign(winner)
    if not assigned then
        diagnostics.lastReason = leaseOrReason or "ASSIGN_FAILED"
        return false, diagnostics.lastReason
    end
    local lease = leaseOrReason
    diagnostics.lastReason, diagnostics.currentLeaseId = "ASSIGNED", lease.leaseId
    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("NPCDecisions.TaskAssignments")
        if previousTaskId and previousTaskId ~= winner.taskId then
            ScalingDiagnostics.Increment("NPCDecisions.TaskSwitches")
        end
    end
    return true, lease
end

-- Immediate decisions still pass through the inbox. Removing the pending
-- entry first prevents a command that needs an immediate response from being
-- evaluated a second time by the next scheduled pump.
function Tasking.Commands.ReevaluateNow(event)
    if type(event) ~= "table" then return false, "TASK_EVENT_REQUIRED" end
    local npcId = tostring(event.npcId or "")
    if npcId == "" then return false, "TASK_EVENT_NPC_REQUIRED" end
    if Tasking.Inbox and Tasking.Inbox.Remove then
        local removed, entry = Tasking.Inbox.Remove(npcId)
        if removed then event.causes = Tasking.Inbox.Causes(entry) end
    end
    local ok, result, reason = H.SafeCall("task_reevaluate_immediate",
        Tasking.Commands.Reevaluate, { npcId = npcId,
            eventId = event.id, domain = event.source }, npcId,
        event.cause or event.type, event)
    if not ok then return false, reason or "TASK_REEVALUATION_FAILED" end
    return result, reason
end

return Tasking
