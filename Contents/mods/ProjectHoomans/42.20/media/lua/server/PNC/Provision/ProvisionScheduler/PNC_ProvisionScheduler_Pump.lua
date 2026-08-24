if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Scheduler = PNC.ProvisionScheduler
local H = Scheduler.Internal
local Registry = PNC.ProvisionRuleRegistry
local Evaluator = PNC.ProvisionEvaluator
local Metrics = PNC.SupplyMetrics

function Scheduler.Pump(now)
    now = tonumber(now) or PNC.Core.Now()
    Scheduler.Bootstrap()
    Scheduler.Audit(now)
    if now - Scheduler.LastPumpAt < Scheduler.SLICE_INTERVAL_MS then return 0 end
    Scheduler.LastPumpAt = now
    local processed = 0
    local inspected = 0
    local maximumInspect = #Scheduler.Queue
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
    Metrics.Increment("provisionSchedulerProcessed", processed)
    H.SyncQueueMetric()
    return processed
end
