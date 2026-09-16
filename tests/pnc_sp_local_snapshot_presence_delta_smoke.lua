local T = require "tests/support/test"

local now = 1000
local fullBuilds = 0
local deltaBuilds = 0
local returnNilDelta = false

local localRecord = {
    id = "local_presence_delta",
    alive = true,
    health = { state = "normal" },
    presenceRevision = 1,
    presenceState = "live",
    x = 10,
    y = 20,
    runtime = {
        pathing = {
            phase = "active",
        },
    },
}

local body = {}

local function buildSnapshot(record)
    fullBuilds = fullBuilds + 1
    return {
        id = record.id,
        alive = true,
        detailMarker = "retained-full-detail",
        healthState = "normal",
        interestDetailed = true,
        presenceRevision = record.presenceRevision,
        presenceState = "live",
        travel = {
            route = {
                { x = 10, y = 20, z = 0 },
            },
        },
        x = record.x,
        y = record.y,
        visualState = {
            anim = "Idle",
            moving = false,
        },
    }
end

local function buildPresenceDelta(record)
    deltaBuilds = deltaBuilds + 1
    if returnNilDelta then
        return nil
    end
    return {
        id = record.id,
        alive = true,
        healthState = "normal",
        interestDetailed = true,
        presenceRevision = record.presenceRevision,
        presenceState = "live",
        travel = {
            phase = "active",
        },
        x = record.x,
        y = record.y,
        visualState = {
            anim = "Walk",
            moving = true,
        },
    }
end

PNC = {
    Const = {
        CLIENT_LOCAL_SNAPSHOT_ATTACK_MS = 50,
        CLIENT_LOCAL_SNAPSHOT_IDLE_MS = 500,
        CLIENT_LOCAL_SNAPSHOT_MOVE_MS = 150,
        CLIENT_LOCAL_SNAPSHOT_SCAN_MS = 50,
        CLIENT_LOCAL_VISUAL_MAINTAIN_MS = 250,
        PRESENCE_LIVE = "live",
    },
    Core = {
        Now = function() return now end,
    },
    Client = {},
    ClientPresenceSync = {
        BodyByID = {
            [localRecord.id] = body,
        },
        BodyByInstanceID = {},
        BodyByLease = {},
        BodyByOnlineID = {},
        Internal = {
            ApplySnapshotFacing = function() end,
            ApplySnapshotToBody = function(snapshot, snapshotBody, remoteReplica)
                T.falsy(remoteReplica, "local snapshot used remote rendering")
                T.equal(snapshotBody, body, "wrong local body rendered")
            end,
            CanRequestRemoteSync = function() return false end,
            IsSnapshotDebugEnabled = function() return false end,
            IsWorldReady = function() return true end,
            LogClientMotionDebug = function() end,
            PruneSnapshotDuplicates = function() end,
            RefreshBodyMap = function() end,
        },
        LocalSnapshotAtByID = {},
        UnresolvedLogAtByID = {},
        lastLocalSnapshotBuildAt = 0,
        lastLocalVisualMaintainAt = 0,
    },
    Network = {
        BuildPresenceDelta = buildPresenceDelta,
        BuildSnapshot = buildSnapshot,
        ClientState = {
            snapshots = {},
        },
    },
    Registry = {
        ForEach = function() end,
        ForEachLive = function(callback)
            callback(localRecord)
        end,
    },
}

local loadScript = T["load"]
loadScript("ProjectHoomans", "client", "PNC/PresenceSync/PNC_ClientPresenceTick.lua")
local sync = PNC.ClientPresenceSync

sync.OnTick()
T.equal(fullBuilds, 1, "initial local detail snapshot was not built")
T.equal(deltaBuilds, 0, "initial local snapshot used the compact payload")

localRecord.x = 14
localRecord.y = 24
now = 1200
sync.OnTick()
T.equal(fullBuilds, 1, "movement rebuilt the full local detail snapshot")
T.equal(deltaBuilds, 1, "movement did not use the compact local presence payload")
T.equal(
    PNC.Network.ClientState.snapshots[localRecord.id].detailMarker,
    "retained-full-detail",
    "compact local refresh discarded detailed snapshot fields"
)
T.equal(
    PNC.Network.ClientState.snapshots[localRecord.id].x,
    localRecord.x,
    "compact local refresh did not update position"
)
T.equal(
    PNC.Network.ClientState.snapshots[localRecord.id].visualState.anim,
    "Walk",
    "compact local refresh did not update visual state"
)
T.equal(
    #PNC.Network.ClientState.snapshots[localRecord.id].travel.route,
    1,
    "compact local refresh discarded the detailed travel route"
)

returnNilDelta = true
localRecord.x = 15
now = 1400
sync.OnTick()
T.equal(deltaBuilds, 2, "invalid compact payload was not attempted")
T.equal(fullBuilds, 2, "invalid compact payload did not fall back to detail")

T.finish("pnc_sp_local_snapshot_presence_delta_smoke")
