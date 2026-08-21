if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
local Service = PNC.ScavengeService
local Internal = Service.Internal
local TERMINAL_STATES = Internal.TERMINAL_STATES
local copy = Internal.Copy
local emit = Internal.Emit
local SNAPSHOT_INTERVAL_MS = 750
local RECORD_BROADCAST_INTERVAL_MS = 2500
local RECORD_BROADCAST_BATCH = 8

local function activity(session, status, entry, reasonOrDetails)
    local details = type(reasonOrDetails) == "table"
        and reasonOrDetails or { reason = reasonOrDetails }
    local npcId = details.npcId and tostring(details.npcId) or nil
    local npc = npcId and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    local row = {
        status = tostring(status or ""),
        entryId = entry and entry.entryId or nil,
        fullType = entry and entry.fullType or nil,
        displayName = entry and entry.displayName or nil,
        sourceType = entry and entry.sourceType or nil,
        sourceLabel = details.sourceLabel
            or entry and entry.sourceLabel or nil,
        npcId = npcId,
        npcName = npc and tostring(npc.name or npc.displayName or npc.id)
            or details.npcName and tostring(details.npcName) or npcId,
        quantity = tonumber(details.quantity)
            or entry and tonumber(entry.quantity) or nil,
        itemCount = tonumber(details.itemCount),
        sceneId = details.sceneId and tostring(details.sceneId) or nil,
        reason = details.reason and tostring(details.reason) or nil,
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
    if shouldSend == false then return end
    local immediate = shouldSend == "immediate"
        or TERMINAL_STATES[session.state] == true
    local last = tonumber(session.lastSnapshotAt) or 0
    if immediate or session.updatedAt - last >= SNAPSHOT_INTERVAL_MS then
        session.snapshotPending = nil
        Service.SendSnapshot(session)
    else
        session.snapshotPending = true
        Internal.Increment("SnapshotsDeferred")
    end
end

local function broadcastRecord(record, reason)
    if not record or not PNC.Network or not PNC.Network.BroadcastRecord then
        return false
    end
    PNC.Network.BroadcastRecord(record, reason or "scavenge_batch")
    return true
end

local function queueRecordBroadcast(session, record, force)
    if not session or not record then return false end
    session.recordBroadcasts = session.recordBroadcasts or {}
    local now = PNC.Core.Now()
    local pending = session.recordBroadcasts[tostring(record.id)] or {
        record = record, count = 0, lastAt = now,
    }
    pending.record = record
    pending.count = pending.count + 1
    session.recordBroadcasts[tostring(record.id)] = pending
    if force == true or pending.count >= RECORD_BROADCAST_BATCH
        or now - pending.lastAt >= RECORD_BROADCAST_INTERVAL_MS
    then
        if broadcastRecord(record, "scavenge_collect_batch") then
            pending.count = 0
            pending.lastAt = now
            Internal.Increment("RecordBroadcastBatches")
        end
    end
    return true
end

local function flushRecordBroadcasts(session, reason, npcId)
    local broadcasts = session and session.recordBroadcasts or {}
    for key, pending in pairs(broadcasts) do
        if (not npcId or tostring(npcId) == tostring(key))
            and tonumber(pending.count) > 0
        then
            if broadcastRecord(pending.record,
                reason or "scavenge_collect_flush")
            then
                pending.count = 0
                pending.lastAt = PNC.Core.Now()
                Internal.Increment("RecordBroadcastBatches")
            end
        end
    end
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
    flushRecordBroadcasts(session, "scavenge_session_release")
    releaseReservations(session, reason or "session_released")
    if not session.worldLootReleased then
        WorldLoot.ReleaseSession(session.worldLootSessionId)
        session.worldLootReleased = true
    end
    Service.Sessions[session.id] = nil
    forEachWorker(session, function(npcId)
        if Service.ByNPC[npcId] == session.id then Service.ByNPC[npcId] = nil end
    end)
    -- Auto Grab and source preferences live in ScavengePolicy ModData. Only
    -- runtime-heavy session references are cleared here.
    session.ownerPlayer = nil
    session.record = nil
    session.candidates = {}
    session.manifest = {}
    session.manifestById = {}
    session.queue = nil
    session.workers = {}
    session.activity = {}
    session.searchClaims = nil
    session.approachBySource = nil
    session.recordBroadcasts = nil
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

Internal.Touch = touch
Internal.QueueRecordBroadcast = queueRecordBroadcast
Internal.FlushRecordBroadcasts = flushRecordBroadcasts
Internal.Activity = activity
Internal.RestorePreviousOrder = restorePreviousOrder
Internal.ReleaseReservations = releaseReservations
Internal.ForEachWorker = forEachWorker
Internal.RemoveSession = removeSession
Internal.MakeSessionRoom = makeSessionRoom

return Service
