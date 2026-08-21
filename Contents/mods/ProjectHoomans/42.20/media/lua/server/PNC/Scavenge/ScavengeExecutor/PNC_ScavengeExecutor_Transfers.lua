if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
local Executor = PNC.ScavengeExecutor
local Internal = Executor.Internal
local Service = PNC.ScavengeService
local Common = PNC.BehaviorCommon
local approachKey = Internal.ApproachKey
local approachLocation = Internal.ApproachLocation
local withinInteractionRadius = Internal.WithinInteractionRadius
local laneBlocked = Internal.LaneBlocked
local resetPath = Internal.ResetPath
local completeLease = Internal.CompleteLease
local destinationStore = Internal.DestinationStore
local workerFor = Internal.WorkerFor
local setWorkerPhase = Internal.SetWorkerPhase
local canCarryEntry = Internal.CanCarryEntry
local queuedEntries = Internal.QueuedEntries
local teamCanClaim = Internal.TeamCanClaim
local clearWorkerAction = Internal.ClearWorkerAction

local function finishSearchAction(session, worker)
    local source = worker.currentSource
    local ok, countOrReason = Service.AppendSourceItems(
        session, source, worker.npcId)
    session.processedCount = session.processedCount + 1
    session.searchClaims[source.sourceToken] = nil
    if ok then
        session.searchedCount = session.searchedCount + 1
        Service.Internal.Activity(session, "SOURCE_SEARCHED", {
            entryId = source.sourceToken, sourceType = source.sourceType,
            sourceLabel = source.sourceLabel or source.label,
        }, {
            npcId = worker.npcId,
            itemCount = tonumber(countOrReason) or 0,
            sourceLabel = source.sourceLabel or source.label,
        })
        Service.Internal.Increment("SourcesSearched")
    else
        session.invalidCount = session.invalidCount + 1
        Service.Internal.Activity(session, "SOURCE_INVALID", {
            entryId = source.sourceToken, sourceType = source.sourceType,
            sourceLabel = source.sourceLabel or source.label,
        }, {
            npcId = worker.npcId,
            reason = countOrReason,
            sourceLabel = source.sourceLabel or source.label,
        })
        Service.Internal.Increment("InvalidSources")
    end
    clearWorkerAction(worker)
    Service.Internal.Touch(session, "SourceSearched", {
        sourceToken = source.sourceToken,
        itemCount = ok and countOrReason or 0,
        reason = ok and nil or countOrReason,
    }, true)
end

local function transferWorkerEntry(session, worker, record, body)
    local entry, group = worker.currentEntry, worker.currentGroup
    if not entry or entry.status ~= "QUEUED" then
        clearWorkerAction(worker)
        return true
    end
    local canCarry, reason = canCarryEntry(record, entry)
    if not canCarry then
        entry.failedWorkers = entry.failedWorkers or {}
        entry.failedWorkers[worker.npcId] = true
        entry.assignedNpcId = nil
        clearWorkerAction(worker)
        return false, reason
    end
    local destination
    destination, reason = destinationStore(record, body)
    if not destination then
        entry.failedWorkers = entry.failedWorkers or {}
        entry.failedWorkers[worker.npcId] = true
        entry.assignedNpcId = nil
        clearWorkerAction(worker)
        return false, reason
    end
    setWorkerPhase(session, worker, "ATOMIC_TRANSFER", "ATOMIC_COMMIT")
    local ok, result = WorldLoot.Transfer({
        sourceToken = group.sourceToken,
        itemToken = entry.itemToken,
        reservationToken = entry.reservationToken,
        destination = destination,
        owner = session.id,
    })
    entry.reservationToken = nil
    entry.assignedNpcId = nil
    if ok then
        entry.status = "COLLECTED"
        entry.failureReason = nil
        session.collectedCount = session.collectedCount + 1
        Service.Internal.Activity(session, "COLLECTED", entry, {
            npcId = worker.npcId,
            quantity = tonumber(entry.quantity) or 1,
            sourceLabel = entry.sourceLabel,
        })
        Service.Internal.Increment("ItemsCollected")
        if PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "inventory")
        end
        if Service.Internal.QueueRecordBroadcast then
            Service.Internal.QueueRecordBroadcast(session, record, false)
        elseif PNC.Network and PNC.Network.BroadcastRecord then
            PNC.Network.BroadcastRecord(record, "scavenge_collect")
        end
    else
        entry.status = "UNAVAILABLE"
        entry.failureReason = tostring(result or "transfer_failed")
        session.unavailableCount = session.unavailableCount + 1
        Service.Internal.Activity(session, "UNAVAILABLE", entry, {
            npcId = worker.npcId,
            reason = entry.failureReason,
            sourceLabel = entry.sourceLabel,
        })
        Service.Internal.Increment("TransferFailures")
    end
    session.queueCount = math.max(0,
        (tonumber(session.queueCount) or 0) - 1)
    clearWorkerAction(worker)
    Service.Internal.Touch(session,
        ok and "ItemCollected" or "ItemUnavailable", {
            entryId = entry.entryId,
            npcId = worker.npcId,
            reason = ok and nil or entry.failureReason,
        }, true)
    return ok
end

Internal.FinishSearchAction = finishSearchAction
Internal.TransferWorkerEntry = transferWorkerEntry

return Executor
