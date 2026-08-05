local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/PresenceSync/"
    .. "PNC_ClientPresenceTick.lua"

local now = 100
local builds = 0
local renders = 0
local renderedAsRemote
local record = {
    id = "sp_attacker",
    alive = true,
    health = { state = "normal" },
    presenceRevision = 1,
    presenceState = "live",
    runtime = {
        attackAction = {
            anim = "PNC_Attack1H1",
            finishAt = 800,
        },
    },
}
local snapshot = {
    id = record.id,
    alive = true,
    attackMode = true,
    healthState = "normal",
    presenceRevision = 1,
    presenceState = "live",
    visualState = {
        anim = "PNC_Attack1H1",
        attackActive = true,
        attackAnim = "PNC_Attack1H1",
        attackFinishAt = 800,
        moving = false,
    },
}
local body = {}

PNC = {
    Const = {
        CLIENT_LOCAL_SNAPSHOT_ATTACK_MS = 50,
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
            [record.id] = body,
        },
        BodyByInstanceID = {},
        BodyByLease = {},
        BodyByOnlineID = {},
        Internal = {
            ApplySnapshotFacing = function() end,
            ApplySnapshotToBody = function(_, resolvedBody, remoteReplica)
                assert(resolvedBody == body, "single-player body was not resolved")
                renders = renders + 1
                renderedAsRemote = remoteReplica
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
        BuildSnapshot = function()
            builds = builds + 1
            return snapshot
        end,
        ClientState = {
            snapshots = {},
        },
    },
    Registry = {
        ForEach = function(callback)
            callback(record)
        end,
    },
}

dofile(FILE)
PNC.ClientPresenceSync.OnTick()

assert(builds == 1, "single-player attack snapshot was not built")
assert(renders == 1, "single-player attack snapshot was not rendered")
assert(
    renderedAsRemote == false,
    "single-player attack was routed through remote interpolation"
)

print("pnc_sp_attack_snapshot_render_smoke: ok")
