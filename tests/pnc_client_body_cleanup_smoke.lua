local T = require "tests/support/test"
T.addPackagePaths()
local now = 100
local scans = 0
local removed = 0
local md = {}
local body = { getModData = function() return md end,
    getOnlineID = function() return 50 end,
    removeFromWorld = function() removed = removed + 1 end }
PNC = {
    Core = { Now = function() return now end, IsClientOnly = function() return true end },
    Const = { PRESENCE_LIVE = "live" },
    Network = { ClientState = { snapshots = {} } },
    Client = { Internal = {} },
    ClientPresenceSync = { Internal = { CanRequestRemoteSync = function() return true end },
        BodyByID = {}, BodyByLease = {}, BodyByOnlineID = {}, BodyByInstanceID = {},
        NativePathStateByBody = {} },
}
getCell = function() scans = scans + 1; error("MP reconciliation must not census zombies") end
local R = require "PNC/PresenceSync/PNC_MultiplayerBodyBinding_Runtime"
T.load("ProjectHoomans", "client", "PNC/Networking/PNC_ClientRosterCommands_Snapshots.lua")
T.load("ProjectHoomans", "client", "PNC/PresenceSync/PNC_ClientPresenceBodies.lua")
local s = { id = "npc_a", alive = true, presenceState = "live", liveBodyLease = "l1",
    liveBodyOnlineID = 50, replicaSequence = 1,
    bodyBinding = {protocol=1, session="s", revision=1, npcId="npc_a",
        operation="bind", incarnation="l1", onlineId=50} }
R.Observe(body)
T.equal(md.PNC_UUID, nil, "vanilla replica cannot invent PNC identity")
PNC.Client.Internal.StoreSnapshot(s)
T.equal(md.PNC_UUID, "npc_a", "accepted binding stamps post-bind cache")
T.equal(PNC.ClientPresenceSync.ResolveBodyForNPC("npc_a"), body,
    "consumer resolves exclusively through canonical binding")
T.equal(PNC.ClientPresenceSync.ResolveBodyForNPC("different", s), nil)
local stale = {id="npc_a", presenceState="live", liveBodyLease="stale",
    liveBodyOnlineID=50, replicaSequence=0}
PNC.Client.Internal.StoreSnapshot(stale)
T.equal(PNC.ClientPresenceSync.ResolveBodyForNPC("npc_a"), body,
    "stale snapshot cannot replace binding")
local spoof = {id="npc_a", presenceState="live", liveBodyLease="l1",
    liveBodyOnlineID=50}
T.equal(R.Resolve(spoof), nil, "UUID/online ID/lease hints alone cannot admit presentation")
PNC.ClientPresenceSync.Internal.RefreshBodyMap(now)
T.equal(scans, 0, "MP refresh performs no zombie census")
T.equal(PNC.ClientPresenceSync.RemoveBodyInstance({id="npc_a",bodyOnlineID=50}), 0)
T.equal(PNC.ClientPresenceSync.RemoveBodyInstance({id="ordinary",bodyOnlineID=50}), 0)
T.equal(removed, 0, "legacy removal hints cannot delete ordinary/recycled zombies")
T.equal(PNC.ClientPresenceSync.Internal.PruneSnapshotDuplicates(s, body), 0)
local state = { snapshot = s }
PNC.ClientPresenceSync.NativePathStateByBody[body] = state
R.Reset()
T.equal(md.PNC_UUID, nil, "connection reset clears only owned cache")
T.equal(PNC.ClientPresenceSync.BodyByID.npc_a, nil)
T.truthy(state.releasePending, "unbind retires stale movement control")
T.equal(R.Resolve(s), nil, "reset requires new authoritative binding")
-- Reconstruct from fresh server proof; exact tuple removal retires only it.
now = 200
R.Observe(body)
s.bodyBinding.revision = 5
T.truthy(R.AcceptSnapshot(s))
local wrong = {id="npc_a",bodyBinding={protocol=1,session="s",revision=6,
    npcId="npc_a",operation="remove",incarnation="old_lease",onlineId=50}}
T.equal(PNC.ClientPresenceSync.RemoveBodyInstance(wrong), 0)
T.equal(removed, 0, "old incarnation cannot remove current body even with later publication")
local exact = {id="npc_a",bodyBinding={protocol=1,session="s",revision=7,
    npcId="npc_a",operation="remove",incarnation="l1",onlineId=50}}
T.equal(PNC.ClientPresenceSync.RemoveBodyInstance(exact), 1)
T.equal(removed, 1, "exact current tuple is removed once")
T.equal(PNC.ClientPresenceSync.RemoveBodyInstance(exact), 0)
T.equal(removed, 1, "duplicate removal is idempotent")
T.equal(R.Resolve(s), nil)
T.equal(R.AcceptSnapshot(s), false, "old live binding cannot revive removed incarnation")
PNC.Core.IsClientOnly = function() return false end
T.equal(R.AcceptSnapshot(s), false, "SP cannot enter MP admission")
return T.finish("pnc_client_body_cleanup_smoke")
