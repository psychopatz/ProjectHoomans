if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ProvisionScheduler = PNC.ProvisionScheduler or {}

local Scheduler = PNC.ProvisionScheduler
local Registry = PNC.ProvisionRuleRegistry
local Evaluator = PNC.ProvisionEvaluator
local Metrics = PNC.SupplyMetrics

Scheduler.Queue = Scheduler.Queue or {}
Scheduler.Queued = Scheduler.Queued or {}
Scheduler.LastPumpAt = Scheduler.LastPumpAt or 0
Scheduler.LastAuditAt = Scheduler.LastAuditAt or 0
Scheduler.Bootstrapped = Scheduler.Bootstrapped == true
Scheduler.SLICE_INTERVAL_MS = 1000
Scheduler.MAX_PER_SLICE = 2
Scheduler.AUDIT_INTERVAL_MS = 10000

local function key(npcID, ruleID)
    return tostring(npcID) .. "|" .. tostring(ruleID)
end

local function worldHour()
    return PNC.NeedsUtils and PNC.NeedsUtils.WorldAgeHours
        and PNC.NeedsUtils.WorldAgeHours() or 0
end

local function syncQueueMetric()
    Metrics.Set("provisionSchedulerQueueSize", #Scheduler.Queue)
    Metrics.Set("provisionDirtyNPCs", Scheduler.DirtyNPCCount())
end

function Scheduler.DirtyNPCCount()
    local seen = {}
    for _, entry in ipairs(Scheduler.Queue) do seen[entry.npcID] = true end
    local count = 0
    for _ in pairs(seen) do count = count + 1 end
    return count
end

function Scheduler.MarkDirty(recordOrID, ruleID, readyAt)
    local npcID = type(recordOrID) == "table" and recordOrID.id or recordOrID
    if not npcID or not Registry.Get(ruleID) then return false end
    local entryKey = key(npcID, ruleID)
    local existing = Scheduler.Queued[entryKey]
    if existing then
        existing.readyAt = math.min(existing.readyAt or 0, readyAt or 0)
        return false
    end
    local entry = { npcID = tostring(npcID), ruleID = tostring(ruleID),
        readyAt = tonumber(readyAt) or 0 }
    Scheduler.Queue[#Scheduler.Queue + 1] = entry
    Scheduler.Queued[entryKey] = entry
    local record = PNC.Registry and PNC.Registry.Get(entry.npcID)
    if record then
        record.runtime = record.runtime or {}
        record.runtime.provision = record.runtime.provision or {
            incoming = {}, refilling = {}, evaluations = {}, dirtyRules = {},
        }
        record.runtime.provision.dirtyRules[ruleID] = true
    end
    syncQueueMetric()
    return true
end

function Scheduler.MarkAllDirty(recordOrID)
    local changed = false
    for _, definition in ipairs(Registry.List()) do
        changed = Scheduler.MarkDirty(recordOrID, definition.id) or changed
    end
    return changed
end

function Scheduler.MarkFactionDirty(factionID)
    local members = PNC.Factions and PNC.Factions.GetMembers
        and PNC.Factions.GetMembers(factionID) or {}
    for _, member in ipairs(members) do
        if member.alive ~= false then Scheduler.MarkAllDirty(member.npcID) end
    end
    return #members
end

function Scheduler.CancelNPC(recordOrID)
    local npcID = tostring(type(recordOrID) == "table"
        and recordOrID.id or recordOrID or "")
    for index = #Scheduler.Queue, 1, -1 do
        if Scheduler.Queue[index].npcID == npcID then
            Scheduler.Queued[key(npcID, Scheduler.Queue[index].ruleID)] = nil
            table.remove(Scheduler.Queue, index)
        end
    end
    syncQueueMetric()
end

function Scheduler.MarkInventoryDirty(record)
    return Scheduler.MarkAllDirty(record)
end

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
    for _, record in pairs(PNC.Registry and PNC.Registry.Data or {}) do
        local factionID = record.affiliation and record.affiliation.factionID
        if record.alive ~= false and factionID then
            if Scheduler.MarkAllDirty(record) then queued = queued + 1 end
        end
    end
    Metrics.Increment("provisionAuditedNPCs", queued)
    return queued
end

local function process(entry)
    local record = PNC.Registry and PNC.Registry.Get(entry.npcID)
    if not record or record.alive == false then
        return true, nil, { ok = false, reason = "npc_missing" }
    end
    local definition = Registry.Get(entry.ruleID)
    if not definition then
        return true, nil, { ok = false, reason = "unknown_rule" }
    end
    local runtime = record.runtime and record.runtime.provision
    if runtime then runtime.dirtyRules[entry.ruleID] = nil end
    Metrics.Increment("provisionEvaluations")
    local evaluation, evaluationReason = Evaluator.Evaluate(record, definition)
    if not evaluation then
        return true, nil, {
            ruleId = definition.id, ok = false,
            reason = evaluationReason or "evaluation_failed",
        }
    end
    if evaluation.satisfied then
        return true, nil, {
            ruleId = definition.id, ok = true, attempted = false,
            reason = "satisfied", onHand = evaluation.onHand,
        }
    end
    if evaluation.incoming > 0 then
        Metrics.Increment("provisionRequestsSuppressedByIncoming")
        return false, worldHour() + 0.02, {
            ruleId = definition.id, ok = false, attempted = false,
            reason = "incoming", onHand = evaluation.onHand,
        }
    end
    local request = Evaluator.BuildRequest(record, definition, evaluation)
    if not request then
        return true, nil, {
            ruleId = definition.id, ok = false, attempted = false,
            reason = "request_not_built", onHand = evaluation.onHand,
        }
    end
    runtime = record.runtime.provision
    runtime.incoming[entry.ruleID] = evaluation.deficit
    runtime.lastRequest = PNC.Core.DeepCopy(request)
    Metrics.Increment("provisionRequestsCreated")
    local ok, reason = PNC.NPCSupplyService.Process(request, {
        acquireOnly = true,
        ignorePersonal = true,
        force = true,
    })
    runtime.incoming[entry.ruleID] = nil
    runtime.lastRequestResult = reason
    if ok then
        Metrics.Increment("provisionRequestsSucceeded")
        return false, worldHour(), {
            ruleId = definition.id, ok = true, attempted = true,
            reason = reason or "acquired", onHand = evaluation.onHand,
        }
    end
    Metrics.Increment("provisionRequestsFailed")
    if reason == "no_supply" then
        Metrics.Increment("provisionStorageShortages")
    end
    local supply = record.runtime and record.runtime.supply
    local lane = supply and supply.byKind
        and supply.byKind[request.resourceKind] or nil
    return false, lane and lane.nextRetry or (worldHour() + 0.25), {
        ruleId = definition.id, ok = false, attempted = true,
        reason = reason or "acquisition_failed", onHand = evaluation.onHand,
    }
end

local function removeQueuedRule(npcID, ruleID)
    local entryKey = key(npcID, ruleID)
    Scheduler.Queued[entryKey] = nil
    for index = #Scheduler.Queue, 1, -1 do
        local entry = Scheduler.Queue[index]
        if key(entry.npcID, entry.ruleID) == entryKey then
            table.remove(Scheduler.Queue, index)
        end
    end
end

function Scheduler.ReconcileRecord(recordOrID)
    local npcID = tostring(type(recordOrID) == "table"
        and recordOrID.id or recordOrID or "")
    local record = PNC.Registry and PNC.Registry.Get(npcID) or nil
    if not record or record.alive == false then return 0, {} end
    local processed = 0
    local results = {}
    for _, definition in ipairs(Registry.List()) do
        removeQueuedRule(npcID, definition.id)
        local complete, readyAt, result = process({
            npcID = npcID, ruleID = definition.id, readyAt = 0,
        })
        results[#results + 1] = result or {
            ruleId = definition.id, ok = false, reason = "unknown",
        }
        processed = processed + 1
        if not complete then
            Scheduler.MarkDirty(npcID, definition.id, readyAt)
        end
    end
    syncQueueMetric()
    return processed, results
end

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
        Scheduler.Queued[key(entry.npcID, entry.ruleID)] = nil
        inspected = inspected + 1
        if (entry.readyAt or 0) <= worldHour() then
            local complete, readyAt = process(entry)
            processed = processed + 1
            if not complete then
                Scheduler.MarkDirty(entry.npcID, entry.ruleID, readyAt)
            end
        else
            Scheduler.MarkDirty(entry.npcID, entry.ruleID, entry.readyAt)
        end
    end
    Metrics.Increment("provisionSchedulerProcessed", processed)
    syncQueueMetric()
    return processed
end

return Scheduler
