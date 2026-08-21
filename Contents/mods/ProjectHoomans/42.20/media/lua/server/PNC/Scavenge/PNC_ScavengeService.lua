if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"

PNC = PNC or {}
PNC.ScavengeService = PNC.ScavengeService or {}

local Service = PNC.ScavengeService
local Const = PNC.Const
local Policy = PNC.ScavengePolicy

Service.Sessions = Service.Sessions or {}
Service.ByNPC = Service.ByNPC or {}
Service.NextSessionId = Service.NextSessionId or 1
Service.Diagnostics = Service.Diagnostics or {
    counters = {}, timings = {}, lastFailure = nil,
}
Service.Listeners = Service.Listeners or {}
Service.MAX_RUNTIME_SESSIONS = 48

local ACTIVE_STATES = {
    DISCOVERING = true,
    TRAVELING_TO_SEARCH_SOURCE = true,
    SEARCHING_SOURCE = true,
    COLLECTION_QUEUED = true,
    TRAVELING_TO_LOOT_SOURCE = true,
    COLLECTING = true,
    ATOMIC_TRANSFER = true,
}

local TERMINAL_STATES = {
    COMPLETED = true, CANCELLED = true, FAILED = true,
}

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function increment(name, amount)
    local counters = Service.Diagnostics.counters
    counters[name] = (tonumber(counters[name]) or 0) + (tonumber(amount) or 1)
    if PNC.PerformanceScalingDiagnostics then
        PNC.PerformanceScalingDiagnostics.Increment("Scavenge." .. name,
            tonumber(amount) or 1)
    end
end

local function emit(eventName, session, details)
    for _, listener in ipairs(Service.Listeners[eventName] or {}) do
        pcall(listener, copy(details), copy(session and {
            sessionId = session.id, npcId = session.npcId,
            state = session.state, revision = session.revision,
        } or nil))
    end
end

function Service.On(eventName, listener)
    if type(listener) ~= "function" then return false end
    eventName = tostring(eventName or "")
    Service.Listeners[eventName] = Service.Listeners[eventName] or {}
    Service.Listeners[eventName][#Service.Listeners[eventName] + 1] = listener
    return true
end

local function normalizePolicy(value)
    value = type(value) == "table" and value or {}
    return {
        containers = value.containers == true,
        floorItems = value.floorItems == true or value.floor == true,
        corpses = value.corpses == true,
    }
end

local function policyEnabled(value)
    return value.containers or value.floorItems or value.corpses
end

local function sessionForNPC(npcId)
    local id = Service.ByNPC[tostring(npcId or "")]
    return id and Service.Sessions[id] or nil
end

local function ownerMatches(session, player)
    local ownerKey = Policy and Policy.OwnerKey and Policy.OwnerKey(player) or nil
    return ownerKey and tostring(ownerKey) == tostring(session.ownerKey)
end

local followsPlayer

local function authorizeNPC(player, npcId)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId or "")) or nil
    if not record then return nil, "npc_not_found" end
    local allowed, reason = PNC.CompanionCommands.CanPlayerCommand(
        record, player, Const.COMPANION_COMMAND_RADIUS)
    if not allowed then return nil, reason end
    return record
end

local function teamRecords(player, arguments)
    local ids = type(arguments.npcIds) == "table"
        and arguments.npcIds or { arguments.npcId }
    local records, seen = {}, {}
    for _, value in ipairs(ids) do
        local id = tostring(value or "")
        if id ~= "" and not seen[id] then
            local record, reason = authorizeNPC(player, id)
            if not record then return nil, reason end
            local existing = sessionForNPC(id)
            local assignedToOwnedRun = existing
                and ownerMatches(existing, player)
                and existing.workers
                and existing.workers[id] ~= nil
            if not followsPlayer(record, player) and not assignedToOwnedRun then
                return nil, "npc_not_following_player"
            end
            seen[id] = true
            records[#records + 1] = record
        end
    end
    if #records < 1 then return nil, "scavenger_team_empty" end
    return records
end

followsPlayer = function(record, player)
    local order = record and record.orderSpec or {}
    if tostring(order.kind or "") ~= tostring(Const.ORDER_FOLLOW or "follow")
    then return false end
    local onlineID = player and player.getOnlineID
        and tonumber(player:getOnlineID()) or nil
    local username = player and player.getUsername
        and tostring(player:getUsername() or "") or ""
    local targetOnlineID = tonumber(order.ownerOnlineID
        or record and record.ownerOnlineID)
    local targetUsername = tostring(order.ownerUsername
        or record and record.ownerUsername or "")
    if onlineID ~= nil and targetOnlineID ~= nil then
        return onlineID == targetOnlineID
    end
    return username ~= "" and targetUsername == username
end

local function activity(session, status, entry, reason)
    local row = {
        status = tostring(status or ""),
        entryId = entry and entry.entryId or nil,
        fullType = entry and entry.fullType or nil,
        displayName = entry and entry.displayName or nil,
        sourceType = entry and entry.sourceType or nil,
        reason = reason and tostring(reason) or nil,
        at = PNC.Core.Now(),
    }
    session.activity[#session.activity + 1] = row
    while #session.activity > 100 do table.remove(session.activity, 1) end
    return row
end

local function touch(session, eventName, details, shouldSend)
    session.revision = (tonumber(session.revision) or 0) + 1
    session.updatedAt = PNC.Core.Now()
    if eventName then emit(eventName, session, details) end
    if shouldSend ~= false then Service.SendSnapshot(session) end
end

local function releaseReservations(session, reason)
    for _, entry in pairs(session.manifestById or {}) do
        if entry.reservationToken then
            WorldLoot.ReleaseReservation(entry.reservationToken, reason)
            entry.reservationToken = nil
        end
    end
end

local function restorePreviousOrder(session, npcId)
    npcId = tostring(npcId or session.npcId or "")
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    if not record then return end
    if PNC.PathService and PNC.PathService.Reset then
        local body = PNC.Registry.GetLiveZombie(record.id)
        PNC.PathService.Reset(body, record)
    end
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        local previous = session.previousOrders
            and session.previousOrders[npcId] or session.previousOrder
        PNC.OrderSystem.SetOrder(record, previous)
    end
end


local function forEachWorker(session, callback)
    for _, npcId in ipairs(session.npcIds or { session.npcId }) do
        callback(tostring(npcId))
    end
end

local function removeSession(session, reason)
    if not session then return false end
    releaseReservations(session, reason or "session_released")
    WorldLoot.ReleaseSession(session.worldLootSessionId)
    Service.Sessions[session.id] = nil
    forEachWorker(session, function(npcId)
        if Service.ByNPC[npcId] == session.id then Service.ByNPC[npcId] = nil end
    end)
    return true
end

local function makeSessionRoom()
    local count = 0
    local oldest
    for _, candidate in pairs(Service.Sessions) do
        count = count + 1
        if TERMINAL_STATES[candidate.state]
            and (not oldest or (tonumber(candidate.updatedAt) or 0)
                < (tonumber(oldest.updatedAt) or 0))
        then oldest = candidate end
    end
    while count >= Service.MAX_RUNTIME_SESSIONS and oldest do
        removeSession(oldest, "session_evicted")
        count = count - 1
        oldest = nil
        for _, candidate in pairs(Service.Sessions) do
            if TERMINAL_STATES[candidate.state]
                and (not oldest or (tonumber(candidate.updatedAt) or 0)
                    < (tonumber(oldest.updatedAt) or 0))
            then oldest = candidate end
        end
    end
    return count < Service.MAX_RUNTIME_SESSIONS
end

local function publicEntry(entry)
    return {
        entryId = entry.entryId,
        sourceToken = entry.sourceToken,
        sourceType = entry.sourceType,
        sourceLabel = entry.sourceLabel,
        fullType = entry.fullType,
        displayName = entry.displayName,
        category = entry.category,
        quantity = entry.quantity,
        x = entry.x, y = entry.y, z = entry.z,
        distanceSq = entry.distanceSq,
        autoGrab = entry.autoGrab == true,
        status = entry.status,
        failureReason = entry.failureReason,
        assignedNpcId = entry.assignedNpcId,
        discoveredByNpcId = entry.discoveredByNpcId,
    }
end

function Service.BuildSnapshot(session)
    if not session then return nil end
    local manifest = {}
    for index = 1, #session.manifest do
        manifest[index] = publicEntry(session.manifest[index])
    end
    local scavengers = {}
    local totalUsed, totalMax = 0, 0
    local taskPhase
    forEachWorker(session, function(npcId)
        local worker = session.workers and session.workers[npcId] or nil
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcId) or nil
        local encumbrance = record and PNC.Inventory.GetEncumbranceState(record)
            or nil
        local lease = PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC
            and PNC.TaskLeaseService.ForNPC(npcId) or nil
        if lease and not taskPhase then taskPhase = lease.phase end
        totalUsed = totalUsed + (tonumber(encumbrance
            and encumbrance.usedWeight) or 0)
        totalMax = totalMax + (tonumber(encumbrance
            and encumbrance.maxWeight) or 0)
        scavengers[#scavengers + 1] = {
            npcId = npcId,
            npcName = tostring(record and record.name or npcId),
            phase = worker and worker.phase or "IDLE",
            carry = encumbrance and copy(encumbrance) or nil,
        }
    end)
    local queue = {}
    for index, group in ipairs(session.queue or {}) do
        queue[index] = { sourceToken = group.sourceToken,
            sourceType = group.sourceType,
            entryCount = #(group.entries or {}), distanceSq = group.distanceSq }
    end
    local progress = 0
    if session.candidateCount > 0 then
        progress = math.floor((session.processedCount / session.candidateCount)
            * 100 + 0.5)
    elseif session.state == "WAITING_FOR_SELECTION"
        or session.state == "COMPLETED"
    then
        progress = 100
    end
    return {
        sessionId = session.id,
        revision = session.revision,
        npcId = session.npcId,
        npcName = session.npcName,
        npcIds = copy(session.npcIds or { session.npcId }),
        scavengers = scavengers,
        state = session.state,
        phase = session.phase,
        progress = progress,
        candidateCount = session.candidateCount,
        searchedCount = session.searchedCount,
        processedCount = session.processedCount,
        unreachableCount = session.unreachableCount,
        invalidCount = session.invalidCount,
        sourceCounts = copy(session.sourceCounts),
        sourcePolicy = copy(session.sourcePolicy),
        manifest = manifest,
        activity = copy(session.activity),
        queueCount = session.queueCount or 0,
        queue = queue,
        queueIndex = session.queueIndex,
        currentSourceToken = session.currentSourceToken,
        taskPhase = taskPhase,
        collectedCount = session.collectedCount or 0,
        unavailableCount = session.unavailableCount or 0,
        truncated = session.truncated == true,
        lastFailure = session.lastFailure,
        carry = totalMax > 0 and {
            usedWeight = totalUsed,
            maxWeight = totalMax,
            ratio = totalUsed / totalMax,
            level = totalUsed > totalMax and "encumbered" or "normal",
        } or nil,
        policy = Policy and Policy.Snapshot(session.ownerPlayer) or nil,
    }
end

function Service.SendSnapshot(session, player)
    if not session then return false end
    player = player or session.ownerPlayer
    if not player or not ownerMatches(session, player) then return false end
    local payload = Service.BuildSnapshot(session)
    if isServer and isServer() == true and sendServerCommand then
        sendServerCommand(player, Const.MODULE, Const.CMD_SCAVENGE_STATE,
            payload)
    elseif PNC.Client and PNC.Client.Internal
        and PNC.Client.Internal.ApplyScavengeSnapshot
    then
        PNC.Client.Internal.ApplyScavengeSnapshot(payload)
    end
    return true
end

function Service.GetSession(sessionId)
    return Service.Sessions[tostring(sessionId or "")]
end

function Service.GetSearchStatus(sessionId)
    local session = Service.GetSession(sessionId)
    return session and Service.BuildSnapshot(session) or nil
end

function Service.GetLootManifest(sessionId)
    local snapshot = Service.GetSearchStatus(sessionId)
    return snapshot and snapshot.manifest or nil
end

function Service.GetCollectionStatus(sessionId)
    return Service.GetSearchStatus(sessionId)
end

function Service.GetAutoGrabPolicy(player)
    return Policy.GetAutoGrab(player)
end

function Service.GetSearchPreferences(player)
    return Policy.GetPreferences(player)
end

function Service.StartSearch(player, arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local records, reason = teamRecords(player, arguments)
    if not records then return false, reason end
    local record = records[1]
    local sourcePolicy = normalizePolicy(arguments.sourcePolicy)
    if not policyEnabled(sourcePolicy) then return false, "source_policy_empty" end
    local radius = math.max(1, math.min(Const.SCAVENGE_MAX_RADIUS,
        math.floor(tonumber(arguments.radius)
            or Const.SCAVENGE_DEFAULT_RADIUS)))
    local replaced = {}
    for _, teamRecord in ipairs(records) do
        local previous = sessionForNPC(teamRecord.id)
        if previous and not replaced[previous.id] then
            replaced[previous.id] = true
            if not TERMINAL_STATES[previous.state] then
                Service.Cancel(player, { sessionId = previous.id,
                    reason = "replaced" })
            else
                removeSession(previous, "replaced_terminal")
            end
        end
    end
    if not makeSessionRoom() then return false, "session_limit" end
    local ownerKey = Policy.OwnerKey(player)
    if not ownerKey then return false, "owner_identity_unavailable" end
    Policy.SetPreferences(player, sourcePolicy)
    local result
    result, reason = WorldLoot.FindSources({
        x = player:getX(), y = player:getY(), z = player:getZ(),
        radius = radius, sourceTypes = sourcePolicy,
        maxCandidates = Const.SCAVENGE_MAX_CANDIDATES,
        ownerToken = ownerKey .. ":" .. tostring(record.id),
    })
    if not result then return false, reason end
    local id = "scavenge:" .. tostring(Service.NextSessionId)
    Service.NextSessionId = Service.NextSessionId + 1
    local npcIds, workers, previousOrders = {}, {}, {}
    for _, teamRecord in ipairs(records) do
        local npcId = tostring(teamRecord.id)
        npcIds[#npcIds + 1] = npcId
        previousOrders[npcId] = copy(teamRecord.orderSpec)
        workers[npcId] = { npcId = npcId, phase = "READY" }
    end
    local session = {
        id = id, revision = 1,
        ownerKey = ownerKey, ownerPlayer = player,
        npcId = tostring(record.id), npcName = tostring(record.name or record.id),
        record = record,
        npcIds = npcIds, workers = workers,
        originX = player:getX(), originY = player:getY(), originZ = player:getZ(),
        radius = radius, sourcePolicy = sourcePolicy,
        candidates = result.sources, candidateCount = #result.sources,
        nextCandidateIndex = 1, processedCount = 0, searchedCount = 0,
        unreachableCount = 0, invalidCount = 0,
        sourceCounts = result.counts,
        worldLootSessionId = result.sessionId,
        manifest = {}, manifestById = {}, nextEntryId = 1,
        activity = {}, state = "DISCOVERING", phase = "DISCOVERING",
        createdAt = PNC.Core.Now(), updatedAt = PNC.Core.Now(),
        previousOrder = copy(record.orderSpec),
        previousOrders = previousOrders,
        runActive = true,
        searchComplete = #result.sources < 1,
        truncated = result.truncated == true,
        collectedCount = 0, unavailableCount = 0,
    }
    Service.Sessions[id] = session
    for _, npcId in ipairs(npcIds) do Service.ByNPC[npcId] = id end
    increment("SearchStarted")
    increment("SourcesScanned", #result.sources)
    emit("SearchStarted", session)
    for _, npcId in ipairs(npcIds) do
        PNC.Tasking.Commands.MarkDirty(npcId, "SCAVENGE_SEARCH_STARTED")
        PNC.Tasking.Commands.Reevaluate(npcId, "SCAVENGE_SEARCH_STARTED")
    end
    Service.SendSnapshot(session)
    return true, "search_started", Service.BuildSnapshot(session)
end

function Service.AppendSourceItems(session, source, discoveredByNpcId)
    local remaining = Const.SCAVENGE_MAX_MANIFEST_ENTRIES - #session.manifest
    if remaining <= 0 then
        session.truncated = true
        increment("ManifestCapHits")
        return true, 0
    end
    local items, reason, info = WorldLoot.ListItems(source.sourceToken, {
        maxItems = remaining,
    })
    if not items then return false, reason end
    for index = 1, #items do
        if #session.manifest >= Const.SCAVENGE_MAX_MANIFEST_ENTRIES then
            session.truncated = true
            increment("ManifestCapHits")
            break
        end
        local item = items[index]
        local entry = {
            entryId = session.id .. ":e:" .. tostring(session.nextEntryId),
            sourceToken = source.sourceToken,
            sourceType = source.sourceType,
            sourceLabel = source.label,
            itemToken = item.itemToken,
            fullType = item.fullType,
            displayName = item.displayName,
            category = item.category,
            quantity = item.quantity or 1,
            x = source.x, y = source.y, z = source.z,
            distanceSq = source.approximateDistanceSq,
            discoveredByNpcId = discoveredByNpcId
                and tostring(discoveredByNpcId) or nil,
            autoGrab = Policy.Matches(session.ownerPlayer, item.fullType),
            status = "AVAILABLE",
        }
        session.nextEntryId = session.nextEntryId + 1
        session.manifest[#session.manifest + 1] = entry
        session.manifestById[entry.entryId] = entry
    end
    if info and info.truncated then session.truncated = true end
    increment("ManifestEntries", #items)
    return true, #items
end

function Service.QueueMultiple(player, arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local session = Service.GetSession(arguments.sessionId)
    if not session then return false, "session_not_found" end
    if not ownerMatches(session, player) then return false, "session_not_owned" end
    local reason
    if session.state == "ATOMIC_TRANSFER" then
        return false, "atomic_transfer_in_progress"
    end
    if TERMINAL_STATES[session.state] or session.state == "PAUSED" then
        return false, "session_not_selectable"
    end
    if tonumber(arguments.revision) ~= tonumber(session.revision) then
        return false, "revision_conflict"
    end
    local ids = type(arguments.entryIds) == "table" and arguments.entryIds or {}
    if #ids < 1 then return false, "selection_empty" end
    local selected = {}
    for index = 1, #ids do
        local entry = session.manifestById[tostring(ids[index] or "")]
        if not entry or entry.status ~= "AVAILABLE"
            and entry.status ~= "QUEUED"
        then return false, "entry_invalid" end
        if selected[entry.entryId] then return false, "entry_duplicate" end
        selected[entry.entryId] = entry
    end
    releaseReservations(session, "queue_replaced")
    for _, entry in ipairs(session.manifest) do
        if entry.status == "QUEUED" then
            entry.status = "AVAILABLE"
            entry.failureReason = nil
            entry.assignedNpcId = nil
        end
    end
    local bySource = {}
    local sourceOrder = {}
    for index = 1, #ids do
        local entry = selected[tostring(ids[index] or "")]
        local reservation
        reservation, reason = WorldLoot.ReserveItem(entry.sourceToken,
            entry.itemToken, session.id)
        if not reservation then
            entry.status = "UNAVAILABLE"
            entry.failureReason = reason
            session.unavailableCount = session.unavailableCount + 1
            increment("UnavailablePickups")
            activity(session, "UNAVAILABLE", entry, reason)
        else
            entry.reservationToken = reservation.reservationToken
            entry.status = "QUEUED"
            activity(session, "QUEUED", entry)
            local group = bySource[entry.sourceToken]
            if not group then
                group = { sourceToken = entry.sourceToken,
                    sourceType = entry.sourceType,
                    sourceLabel = entry.sourceLabel,
                    x = entry.x, y = entry.y, z = entry.z,
                    entries = {}, distanceSq = entry.distanceSq or 0 }
                bySource[entry.sourceToken] = group
                sourceOrder[#sourceOrder + 1] = group
            end
            group.entries[#group.entries + 1] = entry
        end
    end
    table.sort(sourceOrder, function(left, right)
        if left.distanceSq ~= right.distanceSq then
            return left.distanceSq < right.distanceSq
        end
        return left.sourceToken < right.sourceToken
    end)
    session.queue = sourceOrder
    session.queueIndex = 1
    session.queueEntryIndex = 1
    session.queueCount = 0
    for _, group in ipairs(sourceOrder) do
        session.queueCount = session.queueCount + #group.entries
    end
    if session.queueCount < 1 then
        touch(session, "ItemUnavailable", {
            reason = "no_available_entries",
        }, true)
        return false, "no_available_entries"
    end
    session.state = "COLLECTION_QUEUED"
    session.phase = "COLLECTION_QUEUED"
    session.runActive = true
    session.lastFailure = nil
    touch(session, "PickupQueued", { count = session.queueCount }, true)
    increment("PickupRequests", session.queueCount)
    forEachWorker(session, function(npcId)
        local worker = session.workers and session.workers[npcId] or nil
        if worker and worker.phase == "IDLE" then worker.phase = "READY" end
        PNC.Tasking.Commands.MarkDirty(npcId, "SCAVENGE_COLLECTION_QUEUED")
        PNC.Tasking.Commands.Reevaluate(npcId, "SCAVENGE_COLLECTION_QUEUED")
    end)
    return true, "collection_queued", Service.BuildSnapshot(session)
end

function Service.QueuePickup(player, arguments)
    arguments = copy(arguments or {})
    arguments.entryIds = { arguments.entryId }
    return Service.QueueMultiple(player, arguments)
end

function Service.StartCollection(player, arguments)
    return Service.QueueMultiple(player, arguments)
end

function Service.Cancel(player, arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local session = Service.GetSession(arguments.sessionId)
        or sessionForNPC(arguments.npcId)
    if not session then return false, "session_not_found" end
    if not ownerMatches(session, player) then return false, "session_not_owned" end
    if session.state == "ATOMIC_TRANSFER" then
        session.cancelAfterAtomic = true
        activity(session, "CANCEL_PENDING", nil, "atomic_transfer")
        touch(session, "CollectionCancelPending", nil, true)
        return true, "cancel_pending", Service.BuildSnapshot(session)
    end
    session.state = "CANCELLED"
    session.phase = "CANCELLED"
    releaseReservations(session, "cancelled")
    WorldLoot.ReleaseSession(session.worldLootSessionId)
    session.worldLootReleased = true
    activity(session, "CANCELLED", nil, arguments.reason)
    touch(session, "CollectionCancelled", nil, true)
    session.runActive = false
    forEachWorker(session, function(npcId)
        PNC.Tasking.Commands.CancelForNPC(npcId, "SCAVENGE_CANCELLED")
        restorePreviousOrder(session, npcId)
    end)
    increment("Cancelled")
    return true, "cancelled", Service.BuildSnapshot(session)
end

function Service.CancelSearch(player, arguments)
    return Service.Cancel(player, arguments)
end

function Service.CancelCollection(player, arguments)
    return Service.Cancel(player, arguments)
end

function Service.Pause(player, arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local session = Service.GetSession(arguments.sessionId)
        or sessionForNPC(arguments.npcId)
    if not session then return false, "session_not_found" end
    if not ownerMatches(session, player) then return false, "session_not_owned" end
    if session.state == "ATOMIC_TRANSFER" then
        return false, "atomic_transfer_in_progress"
    end
    releaseReservations(session, "paused")
    for _, entry in ipairs(session.manifest or {}) do
        if entry.status == "QUEUED" then
            entry.status = "AVAILABLE"
            entry.failureReason = nil
            entry.assignedNpcId = nil
        end
    end
    session.queue = nil
    session.queueIndex = 1
    session.queueEntryIndex = 1
    session.queueCount = 0
    session.state = "PAUSED"
    session.phase = "PAUSED"
    session.runActive = false
    activity(session, "PAUSED", nil, "return_to_follow")
    touch(session, "ScavengePaused", { reason = "return_to_follow" }, true)
    forEachWorker(session, function(npcId)
        PNC.Tasking.Commands.CancelForNPC(npcId, "SCAVENGE_PAUSED")
        restorePreviousOrder(session, npcId)
    end)
    increment("Paused")
    return true, "paused", Service.BuildSnapshot(session)
end

function Service.SetAutoGrab(player, arguments)
    arguments = type(arguments) == "table" and arguments or {}
    local ok, result = Policy.SetAutoGrab(player, arguments.fullType,
        arguments.enabled == true)
    if not ok then return false, result end
    local session = Service.GetSession(arguments.sessionId)
    if session and ownerMatches(session, player) then
        for _, entry in ipairs(session.manifest) do
            if entry.fullType == arguments.fullType then
                entry.autoGrab = arguments.enabled == true
            end
        end
        touch(session, "AutoGrabChanged", {
            fullType = arguments.fullType,
            enabled = arguments.enabled == true,
        }, true)
    end
    return true, "auto_grab_updated", result
end

function Service.RemoveAutoGrab(player, arguments)
    arguments = copy(arguments or {})
    arguments.enabled = false
    return Service.SetAutoGrab(player, arguments)
end

function Service.SetSearchPreferences(player, arguments)
    local ok, result = Policy.SetPreferences(player,
        arguments and arguments.sourcePolicy)
    return ok, ok and "preferences_updated" or result, result
end

function Service.RequestPolicy(player, arguments)
    local record, reason = authorizeNPC(player, arguments and arguments.npcId)
    if not record then return false, reason end
    return true, "policy_snapshot", {
        policyOnly = true,
        npcId = tostring(record.id),
        npcName = tostring(record.name or record.id),
        sourcePolicy = Policy.GetPreferences(player),
        policy = Policy.Snapshot(player),
        revision = 0,
    }
end

function Service.RequestSnapshot(player, arguments)
    local session = Service.GetSession(arguments and arguments.sessionId)
        or sessionForNPC(arguments and arguments.npcId)
    if not session then return false, "session_not_found" end
    if not ownerMatches(session, player) then return false, "session_not_owned" end
    Service.SendSnapshot(session, player)
    return true, "snapshot_sent", Service.BuildSnapshot(session)
end

function Service.BringBack(record, player)
    local session = record and sessionForNPC(record.id) or nil
    if session then
        releaseReservations(session, "bring_back")
        if not TERMINAL_STATES[session.state] then
            session.state = "CANCELLED"
            session.phase = "CANCELLED"
            activity(session, "BRING_BACK", nil, "return_home")
            WorldLoot.ReleaseSession(session.worldLootSessionId)
            session.worldLootReleased = true
            touch(session, "CollectionCancelled", {
                reason = "bring_back",
            }, true)
        end
        if PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC(record.id) then
            PNC.Tasking.Commands.CancelForNPC(record.id, "SCAVENGE_BRING_BACK")
        end
    end
    if PNC.ColonyStorageService
        and PNC.ColonyStorageService.RequestNPCCourierDeposit
    then
        local ok = PNC.ColonyStorageService.RequestNPCCourierDeposit(player, {
            npcId = record.id,
            requestId = PNC.Core.GenerateID("scavenge_bring_back"),
        })
        if ok == true then return true end
    end
    return false
end

function Service.ReleaseTerminal(sessionId)
    local session = Service.GetSession(sessionId)
    if not session or not TERMINAL_STATES[session.state] then return false end
    return removeSession(session, "terminal_release")
end

function Service.GetDiagnostics()
    local activeSearches, activeCollections = 0, 0
    for _, session in pairs(Service.Sessions) do
        if session.state == "DISCOVERING"
            or session.state == "TRAVELING_TO_SEARCH_SOURCE"
            or session.state == "SEARCHING_SOURCE"
        then activeSearches = activeSearches + 1 end
        if session.state == "COLLECTION_QUEUED"
            or session.state == "TRAVELING_TO_LOOT_SOURCE"
            or session.state == "COLLECTING"
            or session.state == "ATOMIC_TRANSFER"
        then activeCollections = activeCollections + 1 end
    end
    return {
        activeSearchSessions = activeSearches,
        activeCollectionSessions = activeCollections,
        counters = copy(Service.Diagnostics.counters),
        timings = copy(Service.Diagnostics.timings),
        worldLoot = WorldLoot.GetDiagnostics(),
        lastFailure = copy(Service.Diagnostics.lastFailure),
    }
end

Service.Internal = Service.Internal or {}
Service.Internal.ACTIVE_STATES = ACTIVE_STATES
Service.Internal.TERMINAL_STATES = TERMINAL_STATES
Service.Internal.Increment = increment
Service.Internal.Emit = emit
Service.Internal.Touch = touch
Service.Internal.Activity = activity
Service.Internal.RestorePreviousOrder = restorePreviousOrder
Service.Internal.ReleaseReservations = releaseReservations
Service.Internal.SessionForNPC = sessionForNPC
Service.Internal.RemoveSession = removeSession

return Service
