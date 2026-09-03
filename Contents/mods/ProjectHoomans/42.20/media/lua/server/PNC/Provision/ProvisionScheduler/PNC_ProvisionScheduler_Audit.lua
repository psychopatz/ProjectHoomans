if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Scheduler = PNC.ProvisionScheduler
local H = Scheduler.Internal
local Registry = PNC.ProvisionRuleRegistry
local Evaluator = PNC.ProvisionEvaluator
local Metrics = PNC.SupplyMetrics
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics

function Scheduler.Bootstrap()
    if Scheduler.Bootstrapped then return 0 end
    Scheduler.Bootstrapped = true
    local queued = 0
    if PNC.Factions and PNC.Factions.List then
        for _, faction in ipairs(PNC.Factions.List()) do
            queued = queued + Scheduler.MarkFactionDirty(faction.id)
        end
    end
    return queued
end

function Scheduler.Audit(now)
    now = tonumber(now) or PNC.Core.Now()
    if Scheduler.LastAuditAt <= 0 then
        Scheduler.LastAuditAt = now
        return 0
    end
    if now - Scheduler.LastAuditAt < Scheduler.AUDIT_INTERVAL_MS then return 0 end
    Scheduler.LastAuditAt = now
    local queued = 0
    local inspected = 0
    local timerName
    local timerStart
    if ScalingDiagnostics then
        timerName, timerStart = ScalingDiagnostics.BeginTiming(
            "Provision.Audit", now)
    end
    for _, record in pairs(PNC.Registry and PNC.Registry.Data or {}) do
        local factionID = record.affiliation and record.affiliation.factionID
        if record.alive ~= false and factionID then
            inspected = inspected + 1
            if Scheduler.MarkAllDirty(record, nil, true) then
                queued = queued + 1
            end
        end
    end
    if timerName then
        ScalingDiagnostics.EndTiming(timerName, timerStart)
    end
    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("Provision.AuditNPCsInspected", inspected)
        ScalingDiagnostics.Increment("Provision.AuditNPCsQueued", queued)
    end
    Metrics.Increment("provisionAuditedNPCs", queued)
    return queued
end
