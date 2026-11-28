if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Scheduler = PNC.ProvisionScheduler
local H = Scheduler.Internal
local Registry = PNC.ProvisionRuleRegistry
local Evaluator = PNC.ProvisionEvaluator
local Metrics = PNC.SupplyMetrics
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics

function Scheduler.Pump(now)
    now = tonumber(now) or PNC.Core.Now()
    local timerName
    local timerStart
    if ScalingDiagnostics then
        timerName, timerStart = ScalingDiagnostics.BeginTiming(
            "Provision.Pump", now)
        ScalingDiagnostics.Increment("Provision.PumpCalls")
    end
    Scheduler.Bootstrap()
    Scheduler.Audit(now)
    if now - Scheduler.LastPumpAt < Scheduler.SLICE_INTERVAL_MS then
        if timerName then ScalingDiagnostics.EndTiming(timerName, timerStart) end
        return 0
    end
    Scheduler.LastPumpAt = now
    local processed = 0
    local inspected = 0
    local maximumInspect = #Scheduler.Queue
    local processTimerName
    local processTimerStart
    if ScalingDiagnostics then
        processTimerName, processTimerStart = ScalingDiagnostics.BeginTiming(
            "Provision.Process", now)
    end
    local sliceBudgetMs = math.max(1, tonumber(Scheduler.SLICE_TIME_BUDGET_MS) or 4)
    local sliceStartedAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or now
    local worldHour = H.WorldHour()
    local oldQueue = Scheduler.Queue
    local nextQueue = {}
    local deferred = {}
    local budgetHit = false
    for idx = 1, #oldQueue do
        local entry = oldQueue[idx]
        if not budgetHit
            and processed < Scheduler.MAX_PER_SLICE
            and (entry.readyAt or 0) <= worldHour
        then
            inspected = inspected + 1
            Scheduler.Queued[H.Key(entry.npcID, entry.ruleID)] = nil
            local complete, readyAt = H.Process(entry)
            processed = processed + 1
            if not complete then
                deferred[#deferred + 1] = {
                    npcID = entry.npcID,
                    ruleID = entry.ruleID,
                    readyAt = readyAt,
                }
            end
            local elapsed = (PNC.Core and PNC.Core.Now and PNC.Core.Now() or sliceStartedAt)
                - sliceStartedAt
            if elapsed >= sliceBudgetMs then
                budgetHit = true
            end
        else
            inspected = inspected + 1
            nextQueue[#nextQueue + 1] = entry
        end
    end
    Scheduler.Queue = nextQueue
    for idx = 1, #deferred do
        local d = deferred[idx]
        Scheduler.MarkDirty(d.npcID, d.ruleID, d.readyAt)
    end
    if processTimerName then
        ScalingDiagnostics.EndTiming(processTimerName, processTimerStart)
    end
    Metrics.Increment("provisionSchedulerProcessed", processed)
    H.SyncQueueMetric()
    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("Provision.EntriesInspected", inspected)
        ScalingDiagnostics.Increment("Provision.EntriesProcessed", processed)
        ScalingDiagnostics.SetGauge("Provision.QueueSize", #Scheduler.Queue)
    end
    if timerName then ScalingDiagnostics.EndTiming(timerName, timerStart) end
    return processed
end
