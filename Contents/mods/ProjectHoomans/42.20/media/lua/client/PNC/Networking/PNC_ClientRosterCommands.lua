--[[
    PNC Client Roster Commands
    Applies roster synchronization, record deltas, and removal commands.
]]

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local ClientState = PNC.Network.ClientState
local Network = PNC.Network
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function refreshClientBodyIdentityIndex()
    if Network and Network.RefreshClientBodyIdentityIndex then
        Network.RefreshClientBodyIdentityIndex()
    end
end

local function clearPendingRoster()
    ClientState.pendingRoster = nil
    ClientState.pendingRosterRevision = nil
    ClientState.pendingRosterExpectedChunks = nil
    ClientState.pendingRosterExpectedTotal = nil
    ClientState.pendingRosterSyncID = nil
    ClientState.pendingRosterChunks = nil
    ClientState.pendingRosterChunkRecords = nil
    ClientState.pendingRosterReceivedTotal = nil
end

local function rosterSyncID(args)
    return args and (args.syncID or args.requestID) or nil
end

local function requestRosterRetry()
    clearPendingRoster()
    if Client.RequestFullSync then
        Client.RequestFullSync()
    end
end

local function logClientPresenceTransition(current, incoming, eventName)
    local fromState
    local toState
    local orderKind
    if not Diagnostics
        or not Diagnostics.IsFollowerPresenceAuditEnabled
        or Diagnostics.IsFollowerPresenceAuditEnabled() ~= true
        or not Diagnostics.LogFollowerPresence
        or type(current) ~= "table"
        or type(incoming) ~= "table"
    then
        return
    end
    fromState = current.presenceState
    toState = incoming.presenceState
    if fromState == nil or toState == nil or fromState == toState then
        return
    end
    orderKind = incoming.orderKind or current.orderKind
    if tostring(orderKind or "") ~= tostring(Const.ORDER_FOLLOW or "follow") then
        return
    end
    Diagnostics.LogFollowerPresence("client_presence_transition", {
        "npc=" .. tostring(incoming.id or current.id),
        "source=client",
        "event=" .. tostring(eventName or "snapshot"),
        "from=" .. tostring(fromState),
        "to=" .. tostring(toState),
        "order=" .. tostring(orderKind),
        "owner=" .. tostring(incoming.ownerUsername
            or current.ownerUsername or "nil"),
        "ownerOnlineID=" .. tostring(incoming.ownerOnlineID
            or current.ownerOnlineID or "nil"),
        "position=" .. tostring(incoming.x or current.x)
            .. "," .. tostring(incoming.y or current.y)
            .. "," .. tostring(incoming.z or current.z),
        "presenceRevision=" .. tostring(incoming.presenceRevision or "nil"),
    })
end

local function logClientPresenceRemoval(current, id, reason, eventName)
    if not Diagnostics
        or Diagnostics.FollowerPresenceAuditEnabled ~= true
        or not Diagnostics.LogFollowerPresence
        or type(current) ~= "table"
        or current.presenceState ~= Const.PRESENCE_LIVE
        or tostring(current.orderKind or "") ~= tostring(
            Const.ORDER_FOLLOW or "follow"
        )
    then
        return
    end
    Diagnostics.LogFollowerPresence("client_presence_removed", {
        "npc=" .. tostring(id),
        "source=client",
        "event=" .. tostring(eventName or "remove_record"),
        "from=" .. tostring(current.presenceState),
        "to=abstract_or_unavailable",
        "reason=" .. tostring(reason or "unknown"),
        "order=" .. tostring(current.orderKind),
        "owner=" .. tostring(current.ownerUsername or "nil"),
        "ownerOnlineID=" .. tostring(current.ownerOnlineID or "nil"),
    })
end

local function isStaleSnapshot(current, incoming)
    local currentSequence
    local incomingSequence
    local currentPresenceRevision
    local incomingPresenceRevision
    if type(current) ~= "table" or type(incoming) ~= "table" then
        return false
    end
    currentSequence = tonumber(current.replicaSequence)
    incomingSequence = tonumber(incoming.replicaSequence)
    if currentSequence ~= nil then
        return incomingSequence == nil or incomingSequence < currentSequence
    end
    currentPresenceRevision = tonumber(current.presenceRevision)
    incomingPresenceRevision = tonumber(incoming.presenceRevision)
    if currentPresenceRevision ~= nil then
        return incomingPresenceRevision == nil
            or incomingPresenceRevision < currentPresenceRevision
    end
    if incomingSequence ~= nil or incomingPresenceRevision ~= nil then
        return false
    end
    return false
end

local function mergeSnapshot(current, incoming)
    local key
    if type(current) ~= "table" then
        return incoming
    end
    if type(incoming) == "table"
        and type(incoming.travel) == "table"
        and incoming.travel.route == nil
        and type(current.travel) == "table"
        and current.travel.route ~= nil
    then
        incoming.travel.route = current.travel.route
    end
    for key, _ in pairs(incoming or {}) do
        current[key] = incoming[key]
    end
    return current
end

local function storeSnapshot(
    incoming,
    replace,
    suppressIdentityRefresh,
    eventName
)
    local id
    local current
    if type(incoming) ~= "table" or incoming.id == nil then
        return nil
    end
    id = tostring(incoming.id)
    current = ClientState.snapshots[id]
    if incoming.deathMarker ~= true
        and isStaleSnapshot(current, incoming)
    then
        return current
    end
    if Diagnostics and Diagnostics.FollowerPresenceAuditEnabled == true then
        logClientPresenceTransition(current, incoming, eventName)
    end
    if replace == true or incoming.deathMarker == true then
        ClientState.snapshots[id] = incoming
    else
        ClientState.snapshots[id] = mergeSnapshot(
            ClientState.snapshots[id],
            incoming
        )
    end
    if incoming.deathMarker == true then
        if ClientState.characterPayloads then
            ClientState.characterPayloads[id] = nil
        end
    elseif ClientState.characterPayloads
        and ClientState.characterPayloads[id]
    then
        ClientState.characterPayloads[id].snapshot =
            ClientState.snapshots[id]
    end
    if suppressIdentityRefresh ~= true then
        refreshClientBodyIdentityIndex()
    end
    return ClientState.snapshots[id]
end

Internal.StoreSnapshot = storeSnapshot
Internal.IsStaleSnapshot = isStaleSnapshot

Internal.RegisterServerCommand(Const.CMD_FULL_SYNC, function(args)
    local snapshot
    local i
    for i = 1, #(args.snapshots or {}) do
        snapshot = args.snapshots[i]
        if snapshot and snapshot.id then
            storeSnapshot(snapshot, true, true, "full_sync")
        end
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
        local snapshotID = snapshot and snapshot.id
            and tostring(snapshot.id) or nil
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

Internal.RegisterServerCommand(Const.CMD_ROSTER_DELTA, function(args)
    local entry
    local entryID
    local i
    for i = 1, #(args.entries or {}) do
        entry = args.entries[i]
        entryID = nil
        if entry and entry.id then
            entryID = tostring(entry.id)
            local entryRevision = tonumber(entry.revision)
            local lastRevision = ClientState.rosterEntryRevisions
                and tonumber(ClientState.rosterEntryRevisions[entryID]) or nil
            if entryRevision and lastRevision and entryRevision <= lastRevision then
                entry = nil
            elseif entryRevision then
                ClientState.rosterEntryRevisions =
                    ClientState.rosterEntryRevisions or {}
                ClientState.rosterEntryRevisions[entryID] = entryRevision
            end
        end
        if entry and entry.removed == true then
            if Diagnostics and Diagnostics.FollowerPresenceAuditEnabled == true then
                logClientPresenceRemoval(
                    ClientState.snapshots[entryID],
                    entryID,
                    entry.reason,
                    "roster_delta"
                )
            end
            ClientState.snapshots[entryID] = nil
            ClientState.snapshots[entry.id] = nil
            if ClientState.characterPayloads then
                ClientState.characterPayloads[entryID] = nil
                ClientState.characterPayloads[entry.id] = nil
            end
        elseif entry and entry.snapshot and entry.snapshot.id then
            storeSnapshot(entry.snapshot, false, true, "roster_delta")
        end
    end
    if tonumber(args.directoryRevision)
        and tonumber(args.directoryRevision) >= (tonumber(ClientState.rosterRevision) or 0)
    then
        ClientState.rosterRevision = tonumber(args.directoryRevision)
    end
    refreshClientBodyIdentityIndex()
end)

Internal.RegisterServerCommand(Const.CMD_SYNC_RECORD, function(args)
    local snapshot = args.snapshot
    local id
    local directoryRevision
    local lastRevision
    if not snapshot or not snapshot.id then
        return
    end
    id = tostring(snapshot.id)
    directoryRevision = tonumber(args.directoryRevision)
    if directoryRevision then
        lastRevision = ClientState.rosterEntryRevisions
            and tonumber(ClientState.rosterEntryRevisions[id]) or nil
        if not lastRevision or directoryRevision >= lastRevision then
            ClientState.rosterEntryRevisions =
                ClientState.rosterEntryRevisions or {}
            ClientState.rosterEntryRevisions[id] = directoryRevision
        end
        if directoryRevision >= (tonumber(ClientState.rosterRevision) or 0) then
            ClientState.rosterRevision = directoryRevision
        end
    end
    if args.event == "death"
        and PNC.NPCVoice
        and PNC.NPCVoice.Triggers
        and PNC.NPCVoice.Triggers.ObserveDeath
    then
        PNC.NPCVoice.Triggers.ObserveDeath(snapshot)
    end
    if args.event == "interest_exit" or args.event == "interest_enter" then
        storeSnapshot(snapshot, true, false, args.event or "interest_enter")
    else
        storeSnapshot(snapshot, false, false, args.event or "sync_record")
    end
    refreshClientBodyIdentityIndex()
end)

Internal.RegisterServerCommand(Const.CMD_REMOVE_RECORD, function(args)
    local id
    local entryRevision
    local lastRevision
    local current
    if not args.id then
        return
    end
    id = tostring(args.id)
    entryRevision = tonumber(args.revision)
    lastRevision = ClientState.rosterEntryRevisions
        and tonumber(ClientState.rosterEntryRevisions[id]) or nil
    if entryRevision and lastRevision and entryRevision <= lastRevision then
        return
    end
    if entryRevision then
        ClientState.rosterEntryRevisions = ClientState.rosterEntryRevisions or {}
        ClientState.rosterEntryRevisions[id] = entryRevision
    end
    current = ClientState.snapshots[id]
    if Diagnostics and Diagnostics.FollowerPresenceAuditEnabled == true then
        logClientPresenceRemoval(current, id, args.reason, "remove_record")
    end
    ClientState.snapshots[id] = nil
    if ClientState.characterPayloads then
        ClientState.characterPayloads[id] = nil
    end
    refreshClientBodyIdentityIndex()
end)

Internal.RegisterServerCommand(Const.CMD_REMOVE_BODY, function(args)
    if PNC.ClientPresenceSync
        and PNC.ClientPresenceSync.RemoveBodyInstance
    then
        PNC.ClientPresenceSync.RemoveBodyInstance(args)
    end
end)
