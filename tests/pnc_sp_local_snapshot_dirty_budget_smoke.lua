local T = require "tests/support/test"

local now = 1000
local builds = 0
local renderCountByID = {}

local attacker = {
    id = "local_attacker",
    alive = true,
    health = { state = "normal" },
    presenceRevision = 1,
    presenceState = "live",
    runtime = {
        attackAction = {
            anim = "PNC_Attack1H1",
            finishAt = 1800,
        },
    },
}
local idle = {
    id = "local_idle",
    alive = true,
    health = { state = "normal" },
    presenceRevision = 1,
    presenceState = "live",
    runtime = {},
}

local function buildSnapshot(record)
    builds = builds + 1
    local attackAction = record.runtime and record.runtime.attackAction
    local attackActive = attackAction ~= nil
    return {
        id = record.id,
        alive = true,
        attackMode = attackActive,
        healthState = "normal",
        presenceRevision = record.presenceRevision,
        presenceState = "live",
        visualState = {
            anim = attackActive and attackAction.anim or "Idle",
            attackActive = attackActive,
            attackAnim = attackActive and attackAction.anim or "",
            attackFinishAt = attackActive and attackAction.finishAt or 0,
            moving = false,
        },
    }
end

local bodyByID = {
    [attacker.id] = {},
    [idle.id] = {},
}

PNC = {
    Const = {
        CLIENT_LOCAL_SNAPSHOT_ATTACK_MS = 50,
        CLIENT_LOCAL_SNAPSHOT_IDLE_MS = 500,
        CLIENT_LOCAL_SNAPSHOT_SCAN_MS = 50,
        CLIENT_LOCAL_VISUAL_MAINTAIN_MS = 250,
        PRESENCE_LIVE = "live",
    },
    Core = {
        Now = function() return now end,
    },
    Client = {},
    ClientPresenceSync = {
        BodyByID = bodyByID,
        BodyByInstanceID = {},
        BodyByLease = {},
        BodyByOnlineID = {},
        Internal = {
            ApplySnapshotFacing = function() end,
            ApplySnapshotToBody = function(snapshot, body, remoteReplica)
                T.falsy(remoteReplica, "local snapshot used remote rendering")
                T.truthy(body == bodyByID[snapshot.id], "wrong local body rendered")
                renderCountByID[snapshot.id] =
                    (renderCountByID[snapshot.id] or 0) + 1
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
        BuildSnapshot = buildSnapshot,
        ClientState = {
            snapshots = {},
        },
    },
    Registry = {
        ForEach = function() end,
        ForEachLive = function(callback)
            callback(attacker)
            callback(idle)
        end,
    },
}

T.load("ProjectHoomans", "client", "PNC/PresenceSync/PNC_ClientPresenceTick.lua")
local sync = PNC.ClientPresenceSync

sync.OnTick()
T.equal(builds, 2, "initial local snapshots were not built")
T.equal(renderCountByID[attacker.id], 1, "initial attacker was not rendered")
T.equal(renderCountByID[idle.id], 1, "initial idle NPC was not rendered")

now = 1100
sync.OnTick()
T.equal(builds, 3, "only the due local combat snapshot should rebuild")
T.equal(renderCountByID[attacker.id], 2, "due attacker was not rendered")
T.equal(
    renderCountByID[idle.id],
    1,
    "unchanged local NPC rendered during another NPC's combat refresh"
)

T.finish("pnc_sp_local_snapshot_dirty_budget_smoke")
