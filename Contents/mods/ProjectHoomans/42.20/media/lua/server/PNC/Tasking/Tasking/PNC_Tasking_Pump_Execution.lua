-- Bounded lease executor dispatch for the task pump.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Leases = PNC.TaskLeaseService
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local H = Tasking.Internal
local Events = Tasking.Events
local budgetExhausted = H.PumpBudgetExhausted
local puppetOperaSuspends = H.PumpPuppetOperaSuspends
local promoteMaterializedLease = H.PumpPromoteMaterializedLease

local function execute(at, pumpStartedAt)
    local executorSteps = 0
        local executorBudget = Tasking.MAX_EXECUTOR_TICKS_PER_PUMP
        local activeCount = #Leases.Active
        local executorTimerName
        local executorTimerStart
        if ScalingDiagnostics then
            executorTimerName, executorTimerStart = ScalingDiagnostics.BeginTiming(
                "Tasking.Executor", at)
        end
        for _ = 1, math.min(activeCount, executorBudget) do
            if budgetExhausted(pumpStartedAt) then break end
            if #Leases.Active <= 0 then break end
            executorSteps = executorSteps + 1
            Tasking.ExecutorCursor = (Tasking.ExecutorCursor % #Leases.Active) + 1
            local lease = Leases.Get(Leases.Active[Tasking.ExecutorCursor])
            local suspended = puppetOperaSuspends(lease)
            local domainTimerName
            local domainTimerStart
            if ScalingDiagnostics and lease then
                domainTimerName, domainTimerStart = ScalingDiagnostics.BeginTiming(
                    "Tasking.Domain." .. tostring(lease.sourceDomain or "unknown"),
                    at)
            end
            if not suspended then promoteMaterializedLease(lease) end
            local provider = lease and Tasking.Providers[lease.sourceDomain]
            local executor = provider and type(provider.Tick) == "function"
                and provider or lease and Tasking.Executors[lease.executionMode]
            local recoveryState
            if suspended then
                -- Puppet Opera owns the live presentation. Keep the durable task
                -- lease and its provider state intact until the scene releases it;
                -- executor recovery/cancellation must not tear down the state that
                -- will be resumed afterwards.
            elseif lease and lease.cancellationRequested ~= true then
                _, recoveryState = H.RecoverStalledLease(lease, at)
                recoveryState = recoveryState or H.GetRecoveryState(lease, at)
            end
            if recoveryState == "RECOVERED"
                or recoveryState == "RECOVERY_BACKOFF"
                or recoveryState == "RECOVERY_PENDING"
                or recoveryState == "QUARANTINED"
            then
                -- A recovery attempt owns this executor slot. Do not let the
                -- stale executor run again while cleanup is pending/backing off.
            elseif lease and lease.cancellationRequested == true
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
                    if provider and type(provider.OnExecutorFailure) == "function" then
                        H.SafeCall("provider_executor_failure",
                            provider.OnExecutorFailure, {
                                npcId = lease.npcId,
                                leaseId = lease.leaseId,
                                domain = lease.sourceDomain,
                            }, lease, reason or "EXECUTOR_REJECTED")
                    end
                    local recovered, recoveryResult = H.RecoverExecutorFailure(
                        lease, at, "task_executor_failed")
                    Events.Emit("TASK_EXECUTOR_FAILED", {
                        npcId = lease.npcId, source = "Tasking.Pump",
                        entityId = lease.leaseId,
                        payload = { reason = reason or "EXECUTOR_REJECTED",
                            sourceDomain = lease.sourceDomain,
                            recovery = recoveryResult,
                            recovered = recovered == true },
                    })
                else
                    Tasking.Diagnostics.counters.executorTicks =
                        Tasking.Diagnostics.counters.executorTicks + 1
                end
            end
            if domainTimerName then
                ScalingDiagnostics.EndTiming(
                    domainTimerName, domainTimerStart, lease and lease.npcId)
            end
        end
        if executorTimerName then
            ScalingDiagnostics.EndTiming(executorTimerName, executorTimerStart)
        end
    return executorSteps
end

H.PumpExecutors = execute
