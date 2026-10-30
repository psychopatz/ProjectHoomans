local T = require "tests/support/test"
T.addPackagePaths()

local now = 1000
local lookupCount = 0
local md = {}
local body = {
    getOnlineID = function() return 77 end,
    getModData = function() return md end,
    isDead = function() return false end,
    getSquare = function() return {} end,
}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        CLIENT_BODY_SCAN_UNRESOLVED_MS = 200,
    },
    Core = {
        IsClientOnly = function() return true end,
        Now = function() return now end,
    },
    Network = {
        ClientState = { snapshots = {} },
        FindZombieByOnlineID = function(onlineID)
            lookupCount = lookupCount + 1
            T.equal(onlineID, 77,
                "targeted binding recovery looked up the wrong online id")
            return body
        end,
    },
    ClientPresenceSync = {
        BodyByID = {},
        BodyByLease = {},
        BodyByOnlineID = {},
        BodyByInstanceID = {},
        NativePathStateByBody = {},
    },
}

isServer = function() return false end

local Runtime = require
    "PNC/PresenceSync/PNC_MultiplayerBodyBinding_Runtime"

local snapshot = {
    id = "npc_targeted",
    interestDetailed = true,
    alive = true,
    presenceState = "live",
    liveBodyLease = "lease_targeted",
    liveBodyOnlineID = 77,
    bodyBinding = {
        protocol = 1,
        session = "session_targeted",
        revision = 1,
        npcId = "npc_targeted",
        operation = "bind",
        incarnation = "lease_targeted",
        onlineId = 77,
    },
}
PNC.Network.ClientState.snapshots[snapshot.id] = snapshot

-- Bind arrives before OnZombieUpdate observed the replica. AcceptSnapshot must
-- perform one exact online-id recovery and stamp the replicated body.
T.truthy(Runtime.AcceptSnapshot(snapshot),
    "authoritative binding snapshot was rejected")
T.equal(lookupCount, 1,
    "unresolved binding did not perform one targeted replica lookup")
T.equal(Runtime.Resolve(snapshot), body,
    "targeted lookup did not bind the engine replica")
T.equal(md.PNC_UUID, snapshot.id,
    "targeted binding did not stamp npc identity")
T.equal(md.PNC_BodyLease, snapshot.liveBodyLease,
    "targeted binding did not stamp incarnation")
T.equal(md.PNC_MPBound, true,
    "targeted binding did not mark MP ownership")
T.equal(PNC.ClientPresenceSync.BodyByID[snapshot.id], body,
    "targeted binding did not populate client body index")
T.equal(
    PNC.ClientPresenceSync.BodyByOnlineID[tostring(77)],
    body,
    "targeted binding did not populate online-id index"
)

-- Once resolved, repeated UI/presence resolution is O(1) and performs no
-- additional zombie-list/census lookup.
for _ = 1, 5 do
    now = now + 10
    T.equal(Runtime.Resolve(snapshot), body,
        "resolved replica disappeared")
end
T.equal(lookupCount, 1,
    "resolved binding kept rescanning for the replica")

-- If the targeted resolver initially misses, retries are cadence-bounded.
Runtime.Reset()
PNC.ClientPresenceSync.BodyByID = {}
PNC.ClientPresenceSync.BodyByLease = {}
PNC.ClientPresenceSync.BodyByOnlineID = {}
md = {}
local available = false
PNC.Network.FindZombieByOnlineID = function(onlineID)
    lookupCount = lookupCount + 1
    return available and body or nil
end
lookupCount = 0
snapshot.bodyBinding.revision = 2
T.truthy(Runtime.AcceptSnapshot(snapshot),
    "pending binding snapshot was rejected")
T.equal(lookupCount, 1, "initial pending lookup missing")
T.equal(Runtime.Resolve(snapshot), nil,
    "missing replica resolved unexpectedly")
T.equal(lookupCount, 1,
    "pending binding ignored unresolved lookup throttle")
now = now + 250
available = true
T.equal(Runtime.Resolve(snapshot), body,
    "pending binding did not recover after retry cadence")
T.equal(lookupCount, 2,
    "pending binding retry count was not bounded")

return T.finish("pnc_mp_binding_targeted_recovery_smoke")
