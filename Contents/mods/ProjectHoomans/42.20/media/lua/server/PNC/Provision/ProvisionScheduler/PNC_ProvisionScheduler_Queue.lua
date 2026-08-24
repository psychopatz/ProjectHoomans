if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Scheduler = PNC.ProvisionScheduler
local H = Scheduler.Internal
local Registry = PNC.ProvisionRuleRegistry
local Evaluator = PNC.ProvisionEvaluator
local Metrics = PNC.SupplyMetrics

function H.Key(npcID, ruleID)
    return tostring(npcID) .. "|" .. tostring(ruleID)
end

function H.WorldHour()
    return PNC.NeedsUtils and PNC.NeedsUtils.WorldAgeHours
        and PNC.NeedsUtils.WorldAgeHours() or 0
end

function H.SyncQueueMetric()
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

function Scheduler.MarkDirty(
    recordOrID,
    ruleID,
    readyAt,
    preserveExistingReadyAt
)
    local npcID = type(recordOrID) == "table" and recordOrID.id or recordOrID
    if not npcID or not Registry.Get(ruleID) then return false end
    local entryKey = H.Key(npcID, ruleID)
    local existing = Scheduler.Queued[entryKey]
    if existing then
        -- Explicit inventory/policy events are allowed to wake a deferred
        -- rule immediately. The periodic audit is only a completeness net;
        -- it must not erase the supply service's no-stock retry deadline.
        if preserveExistingReadyAt ~= true then
            existing.readyAt = math.min(
                existing.readyAt or 0,
                readyAt or 0
            )
        end
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
    H.SyncQueueMetric()
    return true
end

function Scheduler.MarkAllDirty(
    recordOrID,
    readyAt,
    preserveExistingReadyAt
)
    local changed = false
    for _, definition in ipairs(Registry.List()) do
        changed = Scheduler.MarkDirty(
            recordOrID,
            definition.id,
            readyAt,
            preserveExistingReadyAt
        ) or changed
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
            Scheduler.Queued[H.Key(npcID, Scheduler.Queue[index].ruleID)] = nil
            table.remove(Scheduler.Queue, index)
        end
    end
    H.SyncQueueMetric()
end

function Scheduler.MarkInventoryDirty(record)
    return Scheduler.MarkAllDirty(record)
end
