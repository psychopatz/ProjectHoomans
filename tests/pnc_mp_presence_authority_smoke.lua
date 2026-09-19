local T = require "tests/support/test"

local now = 1000
local clientOnly = true
local snapshotBuilds = 0
local registryScans = 0
local npc = {
    id = "presence_authority_npc",
    alive = true,
    presenceRevision = 1,
    presenceState = "live",
    runtime = {},
}
local snapshots = {}

PNC = {
    Const = {
        CLIENT_LOCAL_SNAPSHOT_IDLE_MS = 500,
        CLIENT_LOCAL_SNAPSHOT_SCAN_MS = 50,
        PRESENCE_LIVE = "live",
    },
    Core = {
        IsClientOnly = function()
            return clientOnly
        end,
        Now = function()
            return now
        end,
    },
    ClientPresenceSync = {},
    Network = {
        ClientState = {
            snapshots = snapshots,
        },
        BuildSnapshot = function(record)
            snapshotBuilds = snapshotBuilds + 1
            return {
                id = record.id,
                alive = true,
                presenceRevision = record.presenceRevision,
                presenceState = "live",
            }
        end,
    },
    Registry = {
        ForEach = function(callback)
            registryScans = registryScans + 1
            callback(npc)
        end,
        ForEachLive = function(callback)
            registryScans = registryScans + 1
            callback(npc)
        end,
    },
}

T.load(
    "ProjectHoomans",
    "client",
    "PNC/PresenceSync/PNC_ClientPresenceRuntime.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/PresenceSync/PNC_ClientPresenceTick_LocalSnapshots.lua"
)

local sync = PNC.ClientPresenceSync
local refreshAuthority =
    sync.Internal.PresenceTick.LocalSnapshots.RefreshAuthority

T.truthy(
    sync.Internal.CanRequestRemoteSync(),
    "pure client role was not recognized as a remote presence replica"
)
T.falsy(
    refreshAuthority(now),
    "pure client rebuilt authoritative presence snapshots"
)
T.equal(registryScans, 0, "pure client scanned the authoritative NPC registry")
T.equal(snapshotBuilds, 0, "pure client built an authoritative NPC snapshot")
T.equal(
    snapshots[npc.id],
    nil,
    "pure client wrote to the authoritative presence snapshot cache"
)

clientOnly = false
now = 1100
T.falsy(
    sync.Internal.CanRequestRemoteSync(),
    "single player/listen server role requested remote presence snapshots"
)
T.truthy(
    refreshAuthority(now),
    "single player/listen server did not build authoritative presence snapshots"
)
T.equal(registryScans, 1, "authoritative role did not scan the live NPC registry")
T.equal(snapshotBuilds, 1, "authoritative role did not build a presence snapshot")
T.equal(
    snapshots[npc.id] and snapshots[npc.id].id,
    npc.id,
    "authoritative snapshot was not stored under the NPC identity"
)

T.finish("pnc_mp_presence_authority_smoke")
