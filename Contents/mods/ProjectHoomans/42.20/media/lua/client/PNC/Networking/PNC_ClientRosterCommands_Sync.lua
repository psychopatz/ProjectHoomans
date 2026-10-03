local Internal = PNC.Client.Internal
local Const = PNC.Const
local ClientState = PNC.Network.ClientState
local requestRosterRetry = Internal.RequestRosterRetry
local clearPendingRoster = Internal.ClearPendingRoster
local rosterSyncID = Internal.RosterSyncID
local isSnapshotRecord = Internal.IsSnapshotRecord
local normalizeSnapshotID = Internal.NormalizeSnapshotID
local isStaleSnapshot = Internal.IsStaleSnapshot
local storeSnapshot = Internal.StoreSnapshot
local refreshClientBodyIdentityIndex =
    Internal.RefreshClientBodyIdentityIndex

Internal.RegisterServerCommand(Const.CMD_FULL_SYNC, function(args)
    local snapshots = args.snapshots
    local snapshot
    local i
    if snapshots == nil then snapshots = {} end
    if type(snapshots) ~= "table" then
        requestRosterRetry()
        return
    end
    -- Validate the complete batch before mutating client state. A malformed
    -- later row must not leave a partially applied full-sync response.
    for i = 1, #snapshots do
        if not isSnapshotRecord(snapshots[i]) then
            requestRosterRetry()
            return
        end
    end
    for i = 1, #snapshots do
        snapshot = snapshots[i]
        storeSnapshot(snapshot, true, true, "full_sync")
    end
    refreshClientBodyIdentityIndex()
end)

Internal.RegisterServerCommand(Const.CMD_ROSTER_SYNC_BEGIN, function(args)
    local syncID = rosterSyncID(args)
    local expectedChunks = tonumber(args.chunkCount)
    local expectedTotal = tonumber(args.total)
    if expectedChunks == nil or expectedChunks < 0
        or expectedChunks ~= math.floor(expectedChunks)
        or (expectedTotal ~= nil and (
            expectedTotal < 0 or expectedTotal ~= math.floor(expectedTotal)
        ))
    then
        requestRosterRetry()
        return
    end
    ClientState.pendingRoster = {}
    ClientState.pendingRosterRevision = args.directoryRevision or 0
    ClientState.pendingRosterExpectedChunks = expectedChunks
    ClientState.pendingRosterExpectedTotal = expectedTotal
    ClientState.pendingRosterSyncID = syncID and tostring(syncID) or nil
    ClientState.pendingRosterChunks = {}
    ClientState.pendingRosterChunkRecords = {}
    ClientState.pendingRosterReceivedTotal = 0
end)

Internal.RegisterServerCommand(Const.CMD_ROSTER_SYNC_CHUNK, function(args)
    local syncID = rosterSyncID(args)
    local chunkIndex = tonumber(args.chunkIndex)
    local expectedChunks = tonumber(ClientState.pendingRosterExpectedChunks)
    local snapshotIDs = {}
    local snapshot
    local i
    if not ClientState.pendingRoster
        or (ClientState.pendingRosterSyncID ~= nil
            and tostring(syncID or "") ~= ClientState.pendingRosterSyncID)
        or (args.directoryRevision ~= nil
            and tostring(args.directoryRevision)
                ~= tostring(ClientState.pendingRosterRevision or ""))
        or (args.chunkCount ~= nil and tonumber(args.chunkCount) ~= expectedChunks)
        or not chunkIndex or chunkIndex ~= math.floor(chunkIndex)
        or not expectedChunks or chunkIndex < 1 or chunkIndex > expectedChunks
        or ClientState.pendingRosterChunks[chunkIndex] ~= nil
        or type(args.snapshots) ~= "table"
    then
        requestRosterRetry()
        return
    end
    for i = 1, #(args.snapshots or {}) do
        snapshot = args.snapshots[i]
        local snapshotID
        if not isSnapshotRecord(snapshot) then
            requestRosterRetry()
            return
        end
        snapshotID = normalizeSnapshotID(snapshot.id)
        if not snapshotID or snapshotIDs[snapshotID]
            or ClientState.pendingRoster[snapshotID] ~= nil
        then
            requestRosterRetry()
            return
        end
        snapshotIDs[snapshotID] = true
        ClientState.pendingRoster[snapshotID] = snapshot
    end
    ClientState.pendingRosterChunks[chunkIndex] = true
    ClientState.pendingRosterChunkRecords[chunkIndex] = snapshotIDs
    ClientState.pendingRosterReceivedTotal =
        (tonumber(ClientState.pendingRosterReceivedTotal) or 0)
            + #args.snapshots
end)

Internal.RegisterServerCommand(Const.CMD_ROSTER_SYNC_END, function(args)
    local receivedChunks = 0
    local syncID = rosterSyncID(args)
    local expectedChunks = tonumber(ClientState.pendingRosterExpectedChunks) or 0
    local expectedTotal = tonumber(ClientState.pendingRosterExpectedTotal)
    local receivedTotal = tonumber(ClientState.pendingRosterReceivedTotal) or 0
    local committed = {}
    local current = ClientState.snapshots or {}
    local incomingRevision = tonumber(ClientState.pendingRosterRevision) or 0
    local currentRevision = tonumber(ClientState.rosterRevision) or 0
    local id
    local incoming
    for _, _ in pairs(ClientState.pendingRosterChunks or {}) do
        receivedChunks = receivedChunks + 1
    end
    if not ClientState.pendingRoster
        or (ClientState.pendingRosterSyncID ~= nil
            and tostring(syncID or "") ~= ClientState.pendingRosterSyncID)
        or (args.directoryRevision ~= nil
            and tostring(args.directoryRevision)
                ~= tostring(ClientState.pendingRosterRevision or ""))
        or (args.chunkCount ~= nil and tonumber(args.chunkCount) ~= expectedChunks)
        or (args.total ~= nil and tonumber(args.total) ~= expectedTotal)
        or incomingRevision < currentRevision
        or receivedChunks ~= expectedChunks
        or (expectedTotal ~= nil and receivedTotal ~= expectedTotal)
    then
        requestRosterRetry()
        return
    end

    -- A full sync is a snapshot of an earlier point in time. Preserve a
    -- newer per-record update that arrived while its chunks were in flight.
    for id, incoming in pairs(ClientState.pendingRoster) do
        if isStaleSnapshot(current[id], incoming) then
            committed[id] = current[id]
        else
            committed[id] = incoming
        end
        ClientState.rosterEntryRevisions = ClientState.rosterEntryRevisions or {}
        if (tonumber(ClientState.rosterEntryRevisions[id]) or 0) < incomingRevision then
            ClientState.rosterEntryRevisions[id] = incomingRevision
        end
    end
    ClientState.snapshots = committed
    ClientState.characterPayloads = {}
    ClientState.rosterRevision = incomingRevision
    clearPendingRoster()
    refreshClientBodyIdentityIndex()
end)
