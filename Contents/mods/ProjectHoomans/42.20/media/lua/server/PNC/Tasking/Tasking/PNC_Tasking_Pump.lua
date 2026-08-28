if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Priority = PNC.TaskPriority
local Leases = PNC.TaskLeaseService
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local H = Tasking.Internal
local Events = Tasking.Events
local Inbox = Tasking.Inbox

local function reconcileOrphanedActivities(at)
    if at < (tonumber(Tasking.NextOrphanReconcileAt) or 0) then
        return 0
    end
    Tasking.NextOrphanReconcileAt = at
        + Tasking.ORPHAN_RECONCILE_INTERVAL_MS
    if not PNC.Registry or not PNC.Registry.ForEach
        or not PNC.FacilityJobs or not PNC.FacilityJobs.Stop
    then return 0 end
    local recovered = 0
    PNC.Registry.ForEach(function(record)
        local activity = record and record.runtime
            and record.runtime.facilityActivity or nil
        local leaseId = activity and tostring(activity.taskLeaseId or "") or ""
        -- Automatic need activities always carry a task lease. Manual and
        -- ambient activities intentionally do not, so they are not treated
        -- as stale just because they are lease-free.
        if activity and activity.automatic == true and leaseId ~= ""
            and not Leases.Get(leaseId)
        then
            local ok, stopped = pcall(PNC.FacilityJobs.Stop, record,
                "orphaned_facility_activity")
            if ok and stopped == true then
                recovered = recovered + 1
                Events.Emit("ORPHANED_FACILITY_ACTIVITY_RECOVERED", {
                    record = record, source = "Tasking.OrphanRecovery",
                })
            end
        end
    end)
    return recovered
end

function Tasking.Commands.Pump(at, budget)
    at = tonumber(at) or PNC.Core.Now()
    if at < Tasking.NextPumpAt then return 0 end
    Tasking.NextPumpAt = at + Tasking.PUMP_INTERVAL_MS
    reconcileOrphanedActivities(at)
    if Tasking.Initialized ~= true then
        Tasking.Initialized = true
        if PNC.Registry and PNC.Registry.ForEach then
            PNC.Registry.ForEach(function(record)
                if record and record.alive ~= false then
                    Events.Emit("TASKING_INITIALIZED", {
                        record = record, source = "Tasking.Initialization",
                    })
                end
            end)
        end
    end
    local processed = 0
    local maximum = math.max(1, math.floor(tonumber(budget)
        or Tasking.MAX_REEVALUATIONS_PER_PUMP))
    while processed < maximum and Inbox.Count() > 0 do
        local entry = Inbox.Pop()
        if entry then
            Tasking.Diagnostics.counters.eventProcesses =
                Tasking.Diagnostics.counters.eventProcesses + 1
            local event = entry.latestEvent
            if event then event.causes = Inbox.Causes(entry) end
            local ok, result, reason = H.SafeCall(
                "task_reevaluate", Tasking.Commands.Reevaluate, {
                    npcId = entry.npcId, eventId = entry.latestEventId,
                    domain = entry.latestEvent
                        and entry.latestEvent.source or nil,
                }, entry.npcId, entry.cause, event)
            if not ok then
                Events.Emit("TASK_REEVALUATION_FAILED", {
                    npcId = entry.npcId, source = "Tasking.Pump",
                    entityId = entry.latestEventId,
                    payload = { error = reason, causes = Inbox.Causes(entry) },
                })
            elseif result == false and reason == "TASK_CLEANUP_FAILED" then
                Events.Emit("TASK_REEVALUATION_RETRY", {
                    npcId = entry.npcId, source = "Tasking.Pump",
                    entityId = entry.latestEventId,
                    payload = { reason = reason },
                })
            end
            processed = processed + 1
        end
    end
    local executorBudget = Tasking.MAX_EXECUTOR_TICKS_PER_PUMP
    local activeCount = #Leases.Active
    local executorSteps = math.min(activeCount, executorBudget)
    for _ = 1, executorSteps do
        if #Leases.Active <= 0 then break end
        Tasking.ExecutorCursor = (Tasking.ExecutorCursor % #Leases.Active) + 1
        local lease = Leases.Get(Leases.Active[Tasking.ExecutorCursor])
        local provider = lease and Tasking.Providers[lease.sourceDomain]
        local executor = provider and type(provider.Tick) == "function"
            and provider or lease and Tasking.Executors[lease.executionMode]
        if lease and lease.cancellationRequested == true
            and not (PNC.TaskRequestDefinitions
                and PNC.TaskRequestDefinitions.NON_INTERRUPTIBLE_PHASE[lease.phase])
        then
            H.StopLease(lease, lease.cancellationReason)
        elseif executor then
            local ok, result, reason = H.SafeCall("executor_tick",
                executor.Tick, { npcId = lease.npcId,
                    leaseId = lease.leaseId,
                    domain = lease.sourceDomain }, lease)
            if not ok or result == false then
                Tasking.Diagnostics.counters.executorFailures =
                    Tasking.Diagnostics.counters.executorFailures + 1
                Events.Emit("TASK_EXECUTOR_FAILED", {
                    npcId = lease.npcId, source = "Tasking.Pump",
                    entityId = lease.leaseId,
                    payload = { reason = reason or "EXECUTOR_REJECTED",
                        sourceDomain = lease.sourceDomain },
                })
            else
                Tasking.Diagnostics.counters.executorTicks =
                    Tasking.Diagnostics.counters.executorTicks + 1
            end
        end
    end
    return processed
end

return Tasking
