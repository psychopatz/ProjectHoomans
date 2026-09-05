local Network = PNC.Network
local Internal = Network.Internal
local Core = PNC.Core
local Const = PNC.Const
local MotionHints = PNC.MotionHints
local ServerState = Network.ServerState

local function nextReplicaSequence(record)
    local runtime
    if not record then
        return 0
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    runtime.replicaSequence = (tonumber(runtime.replicaSequence) or 0) + 1
    return runtime.replicaSequence
end

function Network.BroadcastRecord(record, eventName)
    local payload
    local path
    local recipients
    if not Core.IsAuthority() then
        return
    end
    -- Single-player shares the authoritative registry and live body with its
    -- UI; rebuilding and loopback-dispatching a presence payload every sync
    -- interval has no consumer-side value. Keep explicit mutation events for
    -- existing UI hooks, but remove the high-frequency tick payload and its
    -- observed 11-15 ms BuildPayload spikes.
    if eventName == "tick"
        and (not isServer or isServer() ~= true)
    then
        return
    end
    nextReplicaSequence(record)
    Internal.QueueBroadcastRoster(record, eventName)
    recipients = Internal.CollectRecordRecipients(record)
    if isServer and isServer() and #recipients <= 0 then return end
    payload = Internal.BuildRecordPayload(record, eventName)
    path = record and record.runtime and record.runtime.pathing or nil
    if path and MotionHints and MotionHints.MarkBroadcast then
        MotionHints.MarkBroadcast(record, path, Core.Now())
    end
    Internal.SendRecordPayload(recipients, payload)
end

local function sendInterestRemoval(id, command, payload)
    local state
    if isServer and isServer() then
        for _, state in pairs(ServerState.interests) do
            if state.player and state.ids and state.ids[id] then
                Internal.SendToPlayer(state.player, command, payload)
                state.ids[id] = nil
            end
        end
    else
        triggerEvent("OnServerCommand", Const.MODULE, command, payload)
    end
end

local function deathRemovalSnapshot(id)
    local marker
    local record
    marker = PNC.Registry
        and PNC.Registry.GetDeathMarker
        and PNC.Registry.GetDeathMarker(id)
        or nil
    record = PNC.Registry
        and PNC.Registry.Get
        and PNC.Registry.Get(id)
        or nil
    return marker
        and Network.BuildDeathMarkerSnapshot
        and Network.BuildDeathMarkerSnapshot(marker)
        or record and Network.BuildSnapshot(record)
        or nil
end

local function broadcastDeathRemoval(id, reason)
    local snapshot = deathRemovalSnapshot(id)
    local payload
    if not snapshot then return false end
    Network.QueueRosterSnapshot(id, snapshot, false, reason)
    payload = { event = "death", snapshot = snapshot }
    sendInterestRemoval(id, Const.CMD_SYNC_RECORD, payload)
    return true
end

function Network.BroadcastRemoval(id, reason)
    local payload = { id = id, reason = reason }
    local entry
    local removalReason = tostring(reason or "")
    if not Core.IsAuthority() then
        return
    end
    if string.sub(removalReason, 1, 5) == "death"
        and broadcastDeathRemoval(id, reason)
    then
        return
    end
    Network.QueueRosterDelta(id, true, reason)
    entry = ServerState.rosterDeltas[tostring(id)]
    if entry then
        payload.revision = entry.revision
    end
    sendInterestRemoval(id, Const.CMD_REMOVE_RECORD, payload)
end

function Network.BroadcastDeathMarkerRemoval(id, reason)
    local payload
    local entry
    if not Core.IsAuthority() or id == nil then
        return false
    end
    id = tostring(id)
    payload = {
        id = id,
        reason = tostring(reason or "corpse_removed"),
    }
    Network.QueueRosterDelta(id, true, payload.reason)
    entry = ServerState.rosterDeltas[id]
    if entry then
        payload.revision = entry.revision
    end
    if isServer and isServer() then
        Core.ForEachPlayer(function(player)
            Internal.SendToPlayer(player, Const.CMD_REMOVE_RECORD, payload)
        end)
        for _, state in pairs(ServerState.interests) do
            if state.ids then
                state.ids[id] = nil
            end
        end
    else
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_REMOVE_RECORD,
            payload
        )
    end
    return true
end

function Network.BroadcastBodyRemoval(id, bodyInstanceID, bodyOnlineID, reason)
    local payload
    if not Core.IsAuthority() then
        return false
    end
    payload = {
        id = id and tostring(id) or nil,
        bodyInstanceID = bodyInstanceID ~= nil and tostring(bodyInstanceID) or nil,
        bodyOnlineID = tonumber(bodyOnlineID),
        reason = tostring(reason or "stale_body"),
    }
    if isServer and isServer() then
        -- A stale engine zombie can be present on a client before that client
        -- has entered the NPC interest set. Send instance removals to every
        -- connected player instead of relying on roster interest membership.
        Core.ForEachPlayer(function(player)
            Internal.SendToPlayer(player, Const.CMD_REMOVE_BODY, payload)
        end)
    else
        triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_REMOVE_BODY, payload)
    end
    return true
end

function Network.BroadcastFullSync(targetPlayer, records, requestID)
    local chunkSize = math.max(1, tonumber(Const.ROSTER_CHUNK_SIZE) or 50)
    local total = #(records or {})
    local chunkCount = math.ceil(total / chunkSize)
    local syncID
    local directoryRevision = tonumber(ServerState.rosterRevision) or 0
    local chunkIndex
    local startIndex
    local finishIndex
    local chunk
    local i
    ServerState.fullSyncSerial = (tonumber(ServerState.fullSyncSerial) or 0) + 1
    syncID = requestID and tostring(requestID)
        or "server:roster:" .. tostring(Core.Now()) .. ":"
            .. tostring(ServerState.fullSyncSerial)
    Internal.SendToPlayer(targetPlayer, Const.CMD_ROSTER_SYNC_BEGIN, {
        syncID = syncID,
        directoryRevision = directoryRevision,
        total = total,
        chunkCount = chunkCount,
    })
    for chunkIndex = 1, chunkCount do
        chunk = {}
        startIndex = ((chunkIndex - 1) * chunkSize) + 1
        finishIndex = math.min(total, startIndex + chunkSize - 1)
        for i = startIndex, finishIndex do
            chunk[#chunk + 1] = records[i]
        end
        Internal.SendToPlayer(targetPlayer, Const.CMD_ROSTER_SYNC_CHUNK, {
            syncID = syncID,
            directoryRevision = directoryRevision,
            total = total,
            chunkCount = chunkCount,
            chunkIndex = chunkIndex,
            snapshots = chunk,
        })
    end
    Internal.SendToPlayer(targetPlayer, Const.CMD_ROSTER_SYNC_END, {
        syncID = syncID,
        directoryRevision = directoryRevision,
        total = total,
        chunkCount = chunkCount,
    })
    if isServer and isServer() and targetPlayer then
        local state = ServerState.interests[Internal.PlayerKey(targetPlayer)]
        if state then
            state.ids = {}
        end
        ServerState.lastInterestRefreshAt = 0
    end
end
