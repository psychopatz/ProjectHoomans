local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
local Core = require "PsychopatzCore/Actors/PsychopatzActors"
T.load("ProjectHoomans", "shared", "PNC/Core/Persistence/PNC_Persistence_CoreProvider.lua")

local Adapter = PNC.Persistence.CoreProvider
local registry = Core.NewRegistry()

local dirtyReasons = {}
local coreEnv = {
    Actors = {
        DefaultRegistry = registry,
        Provider = Core.Provider,
    },
    ActorProjectionSync = {
        MarkDirty = function(reason)
            dirtyReasons[#dirtyReasons + 1] = tostring(reason or "")
        end,
    },
}

local actor, actorReason = registry:Create({
    actorId = "npcHostileRoam_POS1",
    identitySeed = "hostile-roam-pos-seed",
    world = {
        location = {
            position = { x = 10653, y = 10288, z = 0 },
        },
    },
})
T.truthy(actor, actorReason)

local record = {
    id = actor.actorId,
    coreActorID = actor.actorId,
    coreBacked = true,
    alive = true,
    presenceState = PNC.Const.PRESENCE_LIVE,
    x = 10650.5,
    y = 10284.25,
    z = 0,
    liveBodyInstanceID = "6553936",
    runtime = {},
}

-- 1. Materialization syncs both lease and canonical Core position.
dirtyReasons = {}
local ok, status = Adapter.SyncPresenceLease(record, nil, coreEnv, { now = 13.7 })
T.truthy(ok, status)
T.equal(status, "materialized")
local afterMat = registry:Get(actor.actorId)
T.equal(afterMat.providerLease.state, "materialized")
T.near(afterMat.world.location.position.x, 10650.5, 0.001)
T.near(afterMat.world.location.position.y, 10284.25, 0.001)
T.truthy(#dirtyReasons > 0, "materialize lease+position sync marks projection dirty")

-- 2. Abstraction after roaming syncs the new coordinates immediately into Core.
record.x = 10623.0
record.y = 10198.4
record.z = 0
record.presenceState = PNC.Const.PRESENCE_ABSTRACT
dirtyReasons = {}
ok, status = Adapter.SyncPresenceLease(record, nil, coreEnv, { now = 14.6 })
T.truthy(ok, status)
T.equal(status, "abstract")
local afterAbs = registry:Get(actor.actorId)
T.equal(afterAbs.providerLease.state, "abstract")
T.near(afterAbs.world.location.position.x, 10623.0, 0.001)
T.near(afterAbs.world.location.position.y, 10198.4, 0.001)
T.truthy(#dirtyReasons > 0, "abstract lease+position sync marks projection dirty")

-- 3. Subsequent position-only SyncPromotedCoreActorToCore dirties projection
-- even when appearance/identity/inventory are unchanged.
record.x = 10621.5
record.y = 10381.6
dirtyReasons = {}
local synced, syncResult = Adapter.SyncPromotedCoreActorToCore(record, coreEnv)
T.truthy(synced, "SyncPromotedCoreActorToCore succeeds for world-only patch")
T.truthy(type(syncResult) == "table" and syncResult.committed == true)
local afterSync = registry:Get(actor.actorId)
T.near(afterSync.world.location.position.x, 10621.5, 0.001)
T.near(afterSync.world.location.position.y, 10381.6, 0.001)
T.truthy(#dirtyReasons > 0, "world-only Core commit marks projection dirty")

-- 4. No-op sync when position already matches Core does not recommit.
local revBefore = afterSync.revision
dirtyReasons = {}
ok, status = Adapter.SyncPresenceLease(record, nil, coreEnv, { now = 14.7 })
T.truthy(ok, status)
T.equal(status, "already_abstract")
T.equal(registry:Get(actor.actorId).revision, revBefore, "unchanged position does not bump revision")
T.equal(#dirtyReasons, 0, "unchanged position does not dirty projection")

T.finish("pnc_core_provider_position_sync_smoke")
