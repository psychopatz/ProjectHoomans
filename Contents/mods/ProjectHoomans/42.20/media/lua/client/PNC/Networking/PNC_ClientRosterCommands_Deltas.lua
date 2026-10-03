local Internal = PNC.Client.Internal
local Const = PNC.Const
local ClientState = PNC.Network.ClientState
local requestRosterRetry = Internal.RequestRosterRetry
local normalizeSnapshotID = Internal.NormalizeSnapshotID
local isSnapshotRecord = Internal.IsSnapshotRecord
local storeSnapshot = Internal.StoreSnapshot
local logClientPresenceRemoval = Internal.LogClientPresenceRemoval
local refreshClientBodyIdentityIndex =
    Internal.RefreshClientBodyIdentityIndex

Internal.RegisterServerCommand(Const.CMD_ROSTER_DELTA, function(args)
    local entries = args.entries
    local entry
    local entryID
    local i
    if entries == nil then entries = {} end
    if type(entries) ~= "table" then
        requestRosterRetry()
        return
    end
    -- Roster deltas can remove or replace several records. Check every row
    -- before applying any of them so a malformed tail cannot leave a partial
    -- batch committed.
    for i = 1, #entries do
        entry = entries[i]
        if type(entry) ~= "table"
            or (entry.id ~= nil and not normalizeSnapshotID(entry.id))
            or (entry.removed == true
                and not normalizeSnapshotID(entry.id))
            or (entry.snapshot ~= nil
                and not isSnapshotRecord(entry.snapshot))
        then
            requestRosterRetry()
            return
        end
    end
    for i = 1, #entries do
        entry = entries[i]
        entryID = nil
        if entry and entry.id then
            entryID = normalizeSnapshotID(entry.id)
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
    if not isSnapshotRecord(snapshot) then
        return
    end
    id = normalizeSnapshotID(snapshot.id)
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
    if args.id == nil then
        return
    end
    id = normalizeSnapshotID(args.id)
    if not id then return end
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
