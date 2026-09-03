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
    while processed < Scheduler.MAX_PER_SLICE
        and #Scheduler.Queue > 0 and inspected < maximumInspect
    do
        local entry = table.remove(Scheduler.Queue, 1)
        Scheduler.Queued[H.Key(entry.npcID, entry.ruleID)] = nil
        inspected = inspected + 1
        if (entry.readyAt or 0) <= H.WorldHour() then
            local complete, readyAt = H.Process(entry)
            processed = processed + 1
            if not complete then
                Scheduler.MarkDirty(entry.npcID, entry.ruleID, readyAt)
            end
        else
            Scheduler.MarkDirty(entry.npcID, entry.ruleID, entry.readyAt)
        end
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
