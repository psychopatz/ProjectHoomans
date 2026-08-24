if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Priority = PNC.TaskPriority
local Leases = PNC.TaskLeaseService
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local H = Tasking.Internal

function Tasking.Commands.Pump(at, budget)
    at = tonumber(at) or PNC.Core.Now()
    if at < Tasking.NextPumpAt then return 0 end
    Tasking.NextPumpAt = at + Tasking.PUMP_INTERVAL_MS
    if Tasking.Initialized ~= true then
        Tasking.Initialized = true
        if PNC.Registry and PNC.Registry.ForEach then
            PNC.Registry.ForEach(function(record)
                if record and record.alive ~= false then
                    Tasking.Commands.MarkDirty(record.id, "TASKING_INITIALIZED")
                end
            end)
        end
    end
    local processed = 0
    local maximum = math.max(1, math.floor(tonumber(budget)
        or Tasking.MAX_REEVALUATIONS_PER_PUMP))
    while processed < maximum and #Tasking.Dirty.queue > 0 do
        local entry = table.remove(Tasking.Dirty.queue, 1)
        if Tasking.Dirty.byNPC[entry.npcId] == entry then
            Tasking.Dirty.byNPC[entry.npcId] = nil
            Tasking.Commands.Reevaluate(entry.npcId, entry.cause)
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
            executor.Tick(lease)
            Tasking.Diagnostics.counters.executorTicks =
                Tasking.Diagnostics.counters.executorTicks + 1
        end
    end
    return processed
end

return Tasking

