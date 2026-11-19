local Codec = require "PNC/Core/Networking/PNC_RosterPortraitCodec"
local Client = PNC.Client
local Internal = Client.Internal
local State = PNC.Network.ClientState
local Const = PNC.Const
local Core = PNC.Core

local MAX_CLIENT_PORTRAITS = 64
local RETRY_MS = 2000
local MIN_REQUEST_SPACING_MS = 100

local entries = {}
local size = 0
local lastRequestAt

function Client.ResetRosterPortraits()
    entries = {}
    size = 0
    lastRequestAt = nil
end

function Client.ForgetRosterPortrait(id)
    if entries[id] then
        entries[id] = nil
        size = size - 1
    end
end

local function reserve(id)
    if entries[id] then return entries[id] end
    if size >= MAX_CLIENT_PORTRAITS then
        local oldestID, oldest
        for otherID, entry in pairs(entries) do
            if not oldest or entry.usedAt < oldest.usedAt then
                oldestID, oldest = otherID, entry
            end
        end
        Client.ForgetRosterPortrait(oldestID)
    end
    local entry = {}
    entries[id] = entry
    size = size + 1
    return entry
end

local function matches(a, b)
    return type(a) == "table" and type(b) == "table"
        and type(a.incarnation) == "string" and a.incarnation == b.incarnation
        and type(a.revision) == "number" and a.revision == b.revision
end

function Client.GetRosterPortrait(id)
    local snapshot = State.snapshots[id]
    local ref = snapshot and snapshot.portraitRef
    if type(ref) ~= "table" or snapshot.deathMarker then
        return snapshot and snapshot.portrait or nil
    end
    local entry = entries[id]
    local now = Core.Now()
    if entry then
        entry.usedAt = now
        if matches(entry.reference, ref) then
            if entry.portrait and (not entry.expiresAt or now < entry.expiresAt) then
                return entry.portrait, entry.displayRevision
            end
            if entry.requestAt and now - entry.requestAt < RETRY_MS then
                return entry.portrait, entry.displayRevision
            end
        end
    end
    local player = Internal.GetPlayer()
    if not player or not sendClientCommand
        or (lastRequestAt and now - lastRequestAt < MIN_REQUEST_SPACING_MS)
    then
        if entry and matches(entry.reference, ref) then
            return entry.portrait, entry.displayRevision
        end
        return nil
    end
    entry = reserve(id)
    if not matches(entry.reference, ref) then entry.portrait = nil end
    entry.usedAt, entry.reference = now, ref
    entry.requestID = Internal.RequestID("roster-portrait")
    entry.requestAt, lastRequestAt = now, now
    sendClientCommand(player, Const.MODULE, Const.CMD_REQUEST_ROSTER_PORTRAIT, {
        id = id, incarnation = ref.incarnation, requestID = entry.requestID,
        forceResolved = entry.forceResolved or nil,
    })
    return entry.portrait, entry.displayRevision
end

Internal.RegisterServerCommand(Const.CMD_ROSTER_PORTRAIT, function(args)
    local entry = entries[args.id]
    local snapshot = State.snapshots[args.id]
    if not entry or not entry.requestID or entry.requestID ~= args.requestID
        or not snapshot or snapshot.deathMarker
        or not matches(snapshot.portraitRef, args.portraitRef)
        or not matches(entry.reference, args.portraitRef)
    then
        return
    end
    local portrait = args.portrait
    if args.portraitCodec == Codec.Fingerprint then
        portrait = Codec.Unpack(args.packedPortrait)
    end
    if type(portrait) ~= "table" then
        entry.forceResolved = true
        entry.requestID = nil
        entry.requestAt = nil
        return
    end
    entry.displayRevision = args.portraitRef.incarnation .. ":" .. tostring(args.portraitRef.revision)
    if args.transient == true then
        entry.displayRevision = entry.displayRevision .. ":" .. entry.requestID
    end
    entry.requestID = nil
    entry.portrait = portrait
    entry.expiresAt = args.transient == true and Core.Now() + RETRY_MS or nil
end)

if Events and Events.OnDisconnect then
    Events.OnDisconnect.Add(function()
        Client.ResetRosterPortraits()
        State.latestRosterRequestID = nil
        State.rosterRevision = 0
        State.rosterEntryRevisions = {}
        State.snapshots = {}
        State.characterPayloads = {}
        Internal.ClearPendingRoster()
    end)
end
