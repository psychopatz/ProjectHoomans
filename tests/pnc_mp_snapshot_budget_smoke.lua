local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "client", "PNC/PresenceSync/")
    .. "PNC_ClientPresenceTick.lua"

local now = 1000
local applyCount = 0
local bindCount = 0
local facingCount = 0
local pruneCount = 0
local controllerPruneCount = 0
local body = {}
local snapshot = {
    id = "remote_budget",
    alive = true,
    healthState = "normal",
    presenceState = "live",
    presenceRevision = 1,
    visualState = {
        anim = "Idle",
        moving = false,
    },
}

PNC = {
    Const = {
        CLIENT_REMOTE_SNAPSHOT_ACTIVE_MS = 100,
        CLIENT_REMOTE_SNAPSHOT_MOVE_MS = 150,
        CLIENT_REMOTE_SNAPSHOT_IDLE_MS = 500,
        CLIENT_REMOTE_FACING_MOVE_MS = 100,
        CLIENT_REMOTE_FACING_IDLE_MS = 220,
        CLIENT_REMOTE_NATIVE_BIND_MS = 250,
        CLIENT_REMOTE_STATE_PRUNE_MS = 5000,
        PRESENCE_LIVE = "live",
    },
    Core = {
        Now = function() return now end,
    },
    Client = {},
    Network = {
        ClientState = {
            snapshots = {
                [snapshot.id] = snapshot,
            },
        },
    },
    ClientPresenceSync = {
        BodyByID = {
            [snapshot.id] = body,
        },
        BodyByOnlineID = {},
        BodyByInstanceID = {},
        BodyByLease = {},
        NativePathStateByBody = {},
        RemoteSnapshotStateByID = {},
        Internal = {
            ApplySnapshotFacing = function()
                facingCount = facingCount + 1
            end,
            ApplySnapshotToBody = function(_, resolvedBody, remoteReplica)
                T.truthy(resolvedBody == body,
                    "remote snapshot resolved the wrong body")
                T.truthy(remoteReplica == true,
                    "remote snapshot used the local presentation lane")
                applyCount = applyCount + 1
            end,
            BindNativePathSnapshot = function(received, resolvedBody)
                T.truthy(received == snapshot,
                    "native binding received an unexpected snapshot")
                T.truthy(resolvedBody == body,
                    "native binding received an unexpected body")
                bindCount = bindCount + 1
                PNC.ClientPresenceSync.NativePathStateByBody[body] = {
                    snapshot = received,
                    owned = false,
                    failed = false,
                }
            end,
            CanRequestRemoteSync = function() return true end,
            IsSnapshotDebugEnabled = function() return false end,
            IsWorldReady = function() return true end,
            LogClientMotionDebug = function() end,
            PruneNativePathControllers = function()
                controllerPruneCount = controllerPruneCount + 1
            end,
            PruneSnapshotDuplicates = function()
                pruneCount = pruneCount + 1
            end,
            RefreshBodyMap = function() end,
        },
        lastLocalSnapshotBuildAt = 0,
        lastLocalVisualMaintainAt = 0,
    },
}

getSpecificPlayer = function() return nil end

T.load(FILE)

PNC.ClientPresenceSync.OnTick()
T.equal(applyCount, 1,
    "first remote snapshot was not presented immediately")
T.equal(bindCount, 1,
    "first remote snapshot was not bound immediately")
T.equal(facingCount, 1,
    "first remote snapshot did not assert facing")
T.equal(pruneCount, 1,
    "first remote snapshot did not run duplicate cleanup")

now = 1016
PNC.ClientPresenceSync.OnTick()
T.equal(applyCount, 1,
    "unchanged idle snapshot was replayed every client tick")
T.equal(bindCount, 1,
    "unchanged native binding was replayed every client tick")
T.equal(facingCount, 1,
    "unchanged idle facing was replayed every client tick")

now = 1250
PNC.ClientPresenceSync.OnTick()
T.equal(applyCount, 1,
    "idle presentation ignored its cadence")
T.equal(bindCount, 2,
    "native binding did not retain its bounded heartbeat")
T.equal(facingCount, 2,
    "idle facing did not retain its bounded reassertion")

now = 1500
PNC.ClientPresenceSync.OnTick()
T.equal(applyCount, 2,
    "idle presentation did not run at its cadence")

-- A transition must interrupt the idle budget even when a test double or
-- engine bridge mutates the current snapshot table in place.
snapshot.visualState.attackActive = true
snapshot.visualState.attackAnim = "PNC_Attack1H1"
snapshot.visualState.attackFinishAt = 1900
now = 1501
PNC.ClientPresenceSync.OnTick()
T.equal(applyCount, 3,
    "in-place action transition was delayed by the idle budget")
T.equal(bindCount, 4,
    "in-place action transition did not refresh native binding")

snapshot.visualState.nativeMoveActive = true
snapshot.visualState.moving = true
now = 1510
PNC.ClientPresenceSync.OnTick()
T.equal(applyCount, 4,
    "native movement transition was delayed by the presentation budget")
T.equal(facingCount, 3,
    "native movement transition applied replica facing")
T.equal(bindCount, 5,
    "native movement transition did not refresh native binding")

now = 1520
PNC.ClientPresenceSync.OnTick()
T.equal(applyCount, 4,
    "active native movement was replayed every client tick")
T.equal(bindCount, 5,
    "active native movement binding was replayed every client tick")
T.equal(controllerPruneCount, 7,
    "native controller pruning stopped running every client tick")

T.finish("pnc_mp_snapshot_budget_smoke")
