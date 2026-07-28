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
local Interpolation = PNC.ClientInterpolation

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

Internal.RegisterServerCommand(Const.CMD_FULL_SYNC, function(args)
    local snapshot
    local i
    ClientState.snapshots = {}
    ClientState.characterPayloads = {}
    if Interpolation and Interpolation.ClearAll then
        Interpolation.ClearAll()
    end
    for i = 1, #(args.snapshots or {}) do
        snapshot = args.snapshots[i]
        ClientState.snapshots[snapshot.id] = snapshot
    end
end)

Internal.RegisterServerCommand(Const.CMD_ROSTER_SYNC_BEGIN, function(args)
    ClientState.pendingRoster = {}
    ClientState.pendingRosterRevision = args.directoryRevision or 0
    ClientState.pendingRosterExpectedChunks = args.chunkCount or 0
    ClientState.pendingRosterChunks = {}
end)

Internal.RegisterServerCommand(Const.CMD_ROSTER_SYNC_CHUNK, function(args)
    local snapshot
    local i
    ClientState.pendingRoster = ClientState.pendingRoster or {}
    for i = 1, #(args.snapshots or {}) do
        snapshot = args.snapshots[i]
        if snapshot and snapshot.id then
            ClientState.pendingRoster[snapshot.id] = snapshot
        end
    end
    if args.chunkIndex then
        ClientState.pendingRosterChunks[args.chunkIndex] = true
    end
end)

Internal.RegisterServerCommand(Const.CMD_ROSTER_SYNC_END, function(args)
    local receivedChunks = 0
    for _, _ in pairs(ClientState.pendingRosterChunks or {}) do
        receivedChunks = receivedChunks + 1
    end
    if receivedChunks < (tonumber(ClientState.pendingRosterExpectedChunks) or 0) then
        ClientState.pendingRoster = nil
        ClientState.pendingRosterChunks = nil
        Client.RequestFullSync()
        return
    end
    ClientState.snapshots = ClientState.pendingRoster or {}
    ClientState.characterPayloads = {}
    ClientState.rosterRevision = args.directoryRevision
        or ClientState.pendingRosterRevision
        or 0
    ClientState.pendingRoster = nil
    ClientState.pendingRosterChunks = nil
    if Interpolation and Interpolation.ClearAll then
        Interpolation.ClearAll()
    end
end)

Internal.RegisterServerCommand(Const.CMD_ROSTER_DELTA, function(args)
    local entry
    local current
    local i
    for i = 1, #(args.entries or {}) do
        entry = args.entries[i]
        if entry.removed == true then
            ClientState.snapshots[entry.id] = nil
            if ClientState.characterPayloads then
                ClientState.characterPayloads[entry.id] = nil
            end
        elseif entry.snapshot and entry.snapshot.id then
            current = ClientState.snapshots[entry.snapshot.id]
            ClientState.snapshots[entry.snapshot.id] = mergeSnapshot(
                current,
                entry.snapshot
            )
        end
    end
    ClientState.rosterRevision = args.directoryRevision
        or ClientState.rosterRevision
end)

Internal.RegisterServerCommand(Const.CMD_SYNC_RECORD, function(args)
    local snapshot = args.snapshot
    if not snapshot or not snapshot.id then
        return
    end
    if args.event == "interest_exit" or args.event == "interest_enter" then
        ClientState.snapshots[snapshot.id] = snapshot
    else
        ClientState.snapshots[snapshot.id] = mergeSnapshot(
            ClientState.snapshots[snapshot.id],
            snapshot
        )
    end
    if ClientState.characterPayloads
        and ClientState.characterPayloads[snapshot.id]
    then
        ClientState.characterPayloads[snapshot.id].snapshot =
            ClientState.snapshots[snapshot.id]
    end
end)

Internal.RegisterServerCommand(Const.CMD_REMOVE_RECORD, function(args)
    if not args.id then
        return
    end
    ClientState.snapshots[args.id] = nil
    if ClientState.characterPayloads then
        ClientState.characterPayloads[args.id] = nil
    end
    if Interpolation and Interpolation.ClearNPC then
        Interpolation.ClearNPC(args.id)
    end
end)

Internal.RegisterServerCommand(Const.CMD_REMOVE_BODY, function(args)
    if PNC.ClientPresenceSync
        and PNC.ClientPresenceSync.RemoveBodyInstance
    then
        PNC.ClientPresenceSync.RemoveBodyInstance(args)
    end
end)
