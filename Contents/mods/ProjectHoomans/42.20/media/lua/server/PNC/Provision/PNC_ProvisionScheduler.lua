if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.ProvisionScheduler = PNC.ProvisionScheduler or {}

local Scheduler = PNC.ProvisionScheduler
local Registry = PNC.ProvisionRuleRegistry
local Evaluator = PNC.ProvisionEvaluator
local Metrics = PNC.SupplyMetrics

Scheduler.Queue = Scheduler.Queue or {}
Scheduler.Queued = Scheduler.Queued or {}
Scheduler.LastPumpAt = Scheduler.LastPumpAt or 0
Scheduler.Bootstrapped = Scheduler.Bootstrapped == true
Scheduler.SLICE_INTERVAL_MS = 1000
Scheduler.MAX_PER_SLICE = 2

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

local function process(entry)
    local record = PNC.Registry and PNC.Registry.Get(entry.npcID)
    if not record or record.alive == false then return true end
    local definition = Registry.Get(entry.ruleID)
    if not definition then return true end
    local runtime = record.runtime and record.runtime.provision
    if runtime then runtime.dirtyRules[entry.ruleID] = nil end
    Metrics.Increment("provisionEvaluations")
    local evaluation = Evaluator.Evaluate(record, definition)
    if not evaluation or evaluation.satisfied then return true end
    if PNC.NPCSupplyService.HasRecentNeedRequest
        and PNC.NPCSupplyService.HasRecentNeedRequest(
            record, definition.resourceKind or definition.selector, 0.05)
    then
        Metrics.Increment("provisionRequestsSuppressedByNeedRequest")
        return false, worldHour() + 0.05
    end
    if evaluation.incoming > 0 then
        Metrics.Increment("provisionRequestsSuppressedByIncoming")
        return false, worldHour() + 0.02
    end
    local request = Evaluator.BuildRequest(record, definition, evaluation)
    if not request then return true end
    runtime = record.runtime.provision
    runtime.incoming[entry.ruleID] = evaluation.deficit
    runtime.lastRequest = PNC.Core.DeepCopy(request)
    Metrics.Increment("provisionRequestsCreated")
    local ok, reason = PNC.NPCSupplyService.Process(request, {
        acquireOnly = true,
        ignorePersonal = true,
    })
    runtime.incoming[entry.ruleID] = nil
    runtime.lastRequestResult = reason
    if ok then
        Metrics.Increment("provisionRequestsSucceeded")
        return false, worldHour()
    end
    Metrics.Increment("provisionRequestsFailed")
    if reason == "no_supply" then
        Metrics.Increment("provisionStorageShortages")
    end
    local supply = record.runtime and record.runtime.supply
    local lane = supply and supply.byKind
        and supply.byKind[request.resourceKind] or nil
    return false, lane and lane.nextRetry or (worldHour() + 0.25)
end

function Scheduler.Pump(now)
    now = tonumber(now) or PNC.Core.Now()
    Scheduler.Bootstrap()
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
