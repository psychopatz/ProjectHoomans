local T = require "tests/support/test"
T.addPackagePaths()

local now = 10000
local modern, legacy = {}, {}
local npc = {
    id = "npc", identitySeed = 77, equipment = { worn = { Hat = "Fixture.Hat" } },
    runtime = { appearanceCache = { hairModel = "Short" } },
    x = 0, y = 0, z = 0, alive = true,
}
local sent, clients, requested = {}, { modern, legacy }, {}
local clientHandlers = {}
local disconnect
Events = { OnDisconnect = { Add = function(handler) disconnect = handler end } }
local function copy(source)
    local output = {}
    for key, value in pairs(source or {}) do output[key] = value end
    return output
end

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        ShallowCopy = copy, DeepCopy = copy,
        ForEachPlayer = function(callback)
            for _, player in ipairs(clients) do callback(player) end
        end,
    },
    Registry = {
        Data = { npc = npc },
        ForEach = function(callback) callback(PNC.Registry.Data.npc) end,
    },
    Client = {
        Internal = {
            GetPlayer = function() return modern end,
            RegisterServerCommand = function(command, callback)
                clientHandlers[command] = callback
            end,
            RequestID = function() return "request-" .. tostring(#requested + 1) end,
        },
    },
}
isServer = function() return true end
sendServerCommand = function(player, _, command, args)
    sent[#sent + 1] = { player = player, command = command, args = args }
end
sendClientCommand = function(_, _, command, args)
    requested[#requested + 1] = { command = command, args = args }
end
require "PNC/Core/Base/PNC_Constants"
require "PNC/Core/Identity/PNC_Identity"
require "PNC/Core/Identity/PNC_Identity_Portrait"
PNC.Identity.GetCharacterSummary = function(record)
    return { identitySeed = record.identitySeed, displayName = "Fixture", isFemale = false }
end
require "PNC/Core/Networking/PNC_Network"
require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerCharacterReplicationCommandHandler"
package.preload["PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldActorMap"] = function()
    return {}
end
require "PNC/Networking/PNC_ClientRosterCommands"
local net, const, router, client = PNC.Network, PNC.Const, PNC.ServerCommandRouter, PNC.Client

local legacyBuild, projectBuild = PNC.Identity.BuildPortraitSummary, PNC.Identity.ProjectPortrait
local legacyCalls, projectCalls = 0, 0
PNC.Identity.BuildPortraitSummary = function(record)
    legacyCalls = legacyCalls + 1
    return legacyBuild(record)
end
PNC.Identity.ProjectPortrait = function(record)
    projectCalls = projectCalls + 1
    return projectBuild(record)
end

local function join(player, protocol)
    sent = {}
    router.Handle(const.CMD_FULL_SYNC_REQUEST, player, { portraitProtocol = protocol })
    T.equal(#sent, 3, "begin, chunk and end")
    if player == modern then
        for _, packet in ipairs(sent) do clientHandlers[packet.command](packet.args) end
    end
    return sent[2].args.snapshots[1]
end

local row = join(modern, const.ROSTER_PORTRAIT_PROTOCOL)
T.equal(row.portrait, nil, "modern roster is lean")
T.truthy(row.portraitRef, "negotiated roster has reference")
T.equal(projectCalls + legacyCalls, 0, "cold lean join does not project portraits")
local oldRow = join(legacy)
T.truthy(oldRow.portrait, "legacy cold join embeds resolved portrait")
T.equal(oldRow.portraitRef, nil, "legacy payload shape is preserved")
local function hydrate(snapshot)
    T.equal(net.ClientState.snapshots.npc.portraitRef.incarnation,
        snapshot.portraitRef.incarnation, "current roster lifetime")
    T.equal(client.GetRosterPortrait("npc"), nil, "initial missing cache")
    local request = requested[#requested]
    T.equal(client.GetRosterPortrait("npc"), nil, "pending requests coalesce")
    T.equal(request, requested[#requested], "unchanged request sequence")
    sent = {}
    router.Handle(request.command, modern, request.args)
    T.equal(#sent, 1, "resolved hydration response")
    return sent[1].args
end

local baseline = hydrate(row)
clientHandlers[const.CMD_ROSTER_PORTRAIT](baseline)
local hydrated = client.GetRosterPortrait("npc")
T.equal(hydrated.identitySeed, 77, "hydration preserves identity")
T.equal(hydrated.equipment.worn.Hat, "Fixture.Hat", "hydration preserves appearance")

local queued = net.ServerState.rosterRevision
npc.inventory = { revision = 99 }
net.RefreshPortraitEquipment(npc)
net.FlushRosterDeltas(now, true)
T.equal(net.ServerState.rosterRevision, queued, "nonvisual change does not queue presentation")
T.equal(projectCalls, 1, "nonvisual change does not rebuild portrait")
npc.equipment.worn.Hat = "Fixture.BlueHat"
net.RefreshPortraitEquipment(npc)
net.RefreshPortraitEquipment(npc)
sent = {}
T.equal(net.FlushRosterDeltas(now, true), 1, "one updated roster entry")
T.equal(net.ServerState.rosterRevision, queued + 1, "visible change queues once")
local nextRow = sent[1].args.entries[1].snapshot
T.equal(nextRow.portraitRef.revision, row.portraitRef.revision + 1, "new revision")
T.equal(sent[2].args.entries[1].snapshot.portrait.equipment.worn.Hat,
    "Fixture.BlueHat", "legacy receives updated resolved portrait")
clientHandlers[const.CMD_SYNC_RECORD]({
    directoryRevision = net.ServerState.rosterRevision + 1, event = "tick",
    snapshot = { id = npc.id, x = 5 },
})
clientHandlers[const.CMD_ROSTER_DELTA](sent[1].args)
T.equal(net.ClientState.snapshots.npc.portraitRef.revision,
    nextRow.portraitRef.revision, "nearby tick cannot suppress an appearance revision")
now = now + 1000
local updated = hydrate(nextRow)
clientHandlers[const.CMD_ROSTER_PORTRAIT](baseline)
T.equal(client.GetRosterPortrait("npc"), nil, "late response does not revive previous revision")
clientHandlers[const.CMD_ROSTER_PORTRAIT](updated)
T.equal(client.GetRosterPortrait("npc").equipment.worn.Hat, "Fixture.BlueHat", "new visual")

net.ForgetPortraitRecord(npc)
net.BroadcastRemoval(npc.id, "removed")
sent = {}
net.FlushRosterDeltas(now, true)
clientHandlers[const.CMD_ROSTER_DELTA](sent[1].args)
T.equal(net.ClientState.snapshots.npc, nil, "removal drops roster and hydrated rows")
local recreated = join(modern, const.ROSTER_PORTRAIT_PROTOCOL)
T.truthy(recreated.portraitRef.incarnation ~= nextRow.portraitRef.incarnation, "ID reuse")
clientHandlers[const.CMD_SYNC_RECORD]({
    directoryRevision = net.ServerState.rosterRevision,
    snapshot = nextRow, event = "interest_enter",
})
T.equal(net.ClientState.snapshots.npc.portraitRef.incarnation,
    recreated.portraitRef.incarnation, "old presence packet cannot restore an old lifetime")
now = now + 1000
local replacement = hydrate(recreated)
clientHandlers[const.CMD_ROSTER_PORTRAIT](updated)
T.equal(client.GetRosterPortrait("npc"), nil, "previous NPC lifetime stays rejected")
clientHandlers[const.CMD_ROSTER_PORTRAIT](replacement)
T.truthy(client.GetRosterPortrait("npc"), "replacement baseline accepted")
client.ResetRosterPortraits()
clientHandlers[const.CMD_ROSTER_PORTRAIT](replacement)
T.equal(client.GetRosterPortrait("npc"), nil, "reconnect requires a fresh request")
disconnect()
T.equal(net.ClientState.rosterRevision, 0, "disconnect clears old revision authority")
T.equal(net.ClientState.snapshots.npc, nil, "disconnect clears old roster")
net.ResetServerState()
now = now + 1000
local afterDisconnect = join(modern, const.ROSTER_PORTRAIT_PROTOCOL)
T.truthy(net.ClientState.snapshots.npc == afterDisconnect,
    "reconnect accepts lower directory revision from fresh server")
local codec = require "PNC/Core/Networking/PNC_RosterPortraitCodec"
local originalPack = codec.Pack
local packCalls = 0
codec.Pack = function(value)
    packCalls = packCalls + 1
    return originalPack(value)
end
npc.equipment.wornVisuals = { Hat = {
    fullType = "Fixture.Hat", textureChoice = 2, baseTexture = 0,
    modelIndex = 3, hue = 0.12345678901234567, decal = "fixture:hat",
    customColor = true, tint = { r = 0.31, g = 0.58, b = 0.49, a = 1 },
} }
net.NegotiateRosterPortraits(modern, const.ROSTER_PORTRAIT_PROTOCOL, codec.Fingerprint)
net.NegotiateRosterPortraits(legacy, const.ROSTER_PORTRAIT_PROTOCOL, codec.Fingerprint)
local function requestPacked(player, requestID, force)
    sent = {}
    router.Handle(const.CMD_REQUEST_ROSTER_PORTRAIT, player, {
        id = npc.id, incarnation = afterDisconnect.portraitRef.incarnation,
        requestID = requestID, forceResolved = force,
    })
    T.equal(#sent, 1, "recipient-specific response")
    return sent[1].args
end
local encoded = requestPacked(modern, "packed-a")
T.truthy(encoded.packedPortrait, "compatible, smaller encoding is selected")
T.equal(encoded.portraitCodec, codec.Fingerprint, "dialect on response")
local shared = requestPacked(legacy, "packed-b")
T.equal(shared.packedPortrait, encoded.packedPortrait, "matching class shares compiled data")
T.equal(packCalls, 1, "matching class encodes once")
T.truthy(requestPacked(modern, "resolved", true).portrait, "repair forces resolved")
net.NegotiateRosterPortraits(legacy, const.ROSTER_PORTRAIT_PROTOCOL, "unknown-catalog-dependent-codec")
T.truthy(requestPacked(legacy, "mismatch").portrait, "mismatched dialect gets resolved")

local overflow
for index = 1, 129 do
    local record = copy(npc)
    record.id = "other-" .. tostring(index)
    PNC.Registry.Data[record.id] = record
    local ref = net.Internal.GetPortraitReference(record)
    now = now + 1000
    sent = {}
    router.Handle(const.CMD_REQUEST_ROSTER_PORTRAIT, modern, {
        id = record.id, incarnation = ref.incarnation, requestID = "cap",
    })
    T.equal(#sent, 1, "capacity preserves demand response")
    if index == 129 then overflow = sent[1].args end
end
T.equal(overflow.transient, true, "retention has a hard bound")
T.truthy(overflow.portrait, "overflow keeps a resolved fallback")
T.finish("pnc_roster_portrait_hydration_smoke")
