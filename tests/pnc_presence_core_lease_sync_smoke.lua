local T = require "tests/support/test"

T.addPackagePaths()
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local SurvivorWorldPresentation = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPresentation"
local registry = Actors.NewRegistry()

local dirtyReasons = {}
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = Actors
PsychopatzCore.Actors.DefaultRegistry = registry
PsychopatzCore.ActorProjectionSync = {
    MarkDirty = function(reason)
        dirtyReasons[#dirtyReasons + 1] = tostring(reason or "")
        return true
    end,
}

local liveBodies = {}
PNC = PNC or {}
PNC.Core = PNC.Core or {}
PNC.Core.IsAuthority = function() return true end
PNC.Core.Now = function() return 1000 end
PNC.Registry = {
    Data = {},
    MarkDirty = function() end,
    GetLiveZombie = function(id) return liveBodies[tostring(id)] end,
    Get = function(id) return PNC.Registry.Data[tostring(id)] end,
    AddRecord = function(rec)
        PNC.Registry.Data[tostring(rec.id)] = rec
        return true
    end,
}
PNC.Persistence = PNC.Persistence or {}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Persistence/PNC_Persistence_CoreProvider.lua")

local Adapter = PNC.Persistence.CoreProvider
local worldRegistry = {
    ListGroups = function() return {} end,
}

-- 1. Adopted ProjectHoomans actor starts abstract, then transitions to
--    materialized when live and back to abstract when dematerialized.
local record = {
    id = "npc:live-badge:1",
    name = "Myrna Patz",
    displayName = "Myrna Patz",
    identitySeed = "myrna-patz-seed",
    archetypeID = "core.survivor",
    x = 100,
    y = 200,
    z = 0,
    runtime = {},
}
local adopted, adoptReason = Adapter.EnsureActor(record, PsychopatzCore)
T.truthy(adopted, adoptReason)
PNC.Registry.Data[record.id] = record

local canonical = registry:Get(record.id)
T.equal(canonical.providerLease.state, "abstract",
    "adopted actor starts abstract before materialization")

local liveBody = {
    getPersistentOutfitID = function() return 424242 end,
    getOnlineID = function() return -1 end,
}
record.presenceState = PNC.Const.PRESENCE_LIVE
liveBodies[record.id] = liveBody

local synced, syncReason = Adapter.SyncPresenceLease(
    record, liveBody, PsychopatzCore, { now = 12 }
)
T.truthy(synced, syncReason)
T.equal(syncReason, "materialized",
    "live transition commits materialized providerLease")

canonical = registry:Get(record.id)
T.equal(canonical.providerLease.state, "materialized",
    "Core actor lease state is materialized while NPC is live")
T.equal(canonical.providerLease.bodyID, "424242",
    "Core actor lease records the live bodyID")
T.equal(dirtyReasons[#dirtyReasons], "presence_materialize",
    "materialization marks ActorProjectionSync dirty")

local entry, entryErr = SurvivorWorldPresentation.BuildActorEntry(
    worldRegistry, canonical, nil, 12, {}
)
T.truthy(entry, entryErr)
T.equal(entry.providerState, "materialized",
    "SurvivorWorld map projection emits materialized providerState")
T.equal(entry.presenceState, "materialized",
    "SurvivorWorld map projection emits materialized presenceState")

-- 2. Idempotent repeat sync with same bodyID does not fail.
local repeatOk, repeatReason = Adapter.SyncPresenceLease(
    record, liveBody, PsychopatzCore, { now = 13 }
)
T.truthy(repeatOk, repeatReason)
T.equal(repeatReason, "already_materialized",
    "repeat sync with same bodyID is idempotent")

-- 3. AnnotateExistingCoreRecord never downgrades a live record to abstract
--    even if Core lease hasn't been synced yet.
local drifted = {
    id = "npc:live-badge:drifted",
    name = "Drifted Live",
    identitySeed = "drifted-live-seed",
    archetypeID = "core.survivor",
    x = 120,
    y = 220,
    z = 0,
    runtime = {},
}
T.truthy(Adapter.EnsureActor(drifted, PsychopatzCore))
PNC.Registry.Data[drifted.id] = drifted
drifted.presenceState = PNC.Const.PRESENCE_LIVE
liveBodies[drifted.id] = {
    getPersistentOutfitID = function() return 777777 end,
}
local annOk, annReason = Adapter.AnnotateExistingCoreRecord(
    drifted, PsychopatzCore
)
T.truthy(annOk, annReason)
T.equal(drifted.presenceState, PNC.Const.PRESENCE_LIVE,
    "AnnotateExistingCoreRecord preserves live presenceState")

-- 4. SyncPromotedCoreActorToCore self-heals a drifted live record's lease.
local healOk, healRes = Adapter.SyncPromotedCoreActorToCore(
    drifted, PsychopatzCore
)
T.truthy(healOk, tostring(healRes))
local healedActor = registry:Get(drifted.id)
T.equal(healedActor.providerLease.state, "materialized",
    "SyncPromotedCoreActorToCore self-heals drifted live lease to materialized")
T.equal(healedActor.providerLease.bodyID, "777777",
    "SyncPromotedCoreActorToCore records healed bodyID")

-- 5. Abstract transition dematerializes the Core providerLease.
record.presenceState = PNC.Const.PRESENCE_ABSTRACT
liveBodies[record.id] = nil
local absOk, absReason = Adapter.SyncPresenceLease(
    record, nil, PsychopatzCore, { now = 15 }
)
T.truthy(absOk, absReason)
T.equal(absReason, "abstract",
    "abstract transition dematerializes Core providerLease")
canonical = registry:Get(record.id)
T.equal(canonical.providerLease.state, "abstract",
    "Core actor lease returns to abstract when NPC is abstracted")
T.equal(canonical.providerLease.bodyID, nil,
    "Core actor lease clears bodyID when abstracted")

-- 6. Non-Hoomans abstract actor (e.g. PsychopatzCore) switches cleanly to
--    ProjectHoomans materialized when Hoomans materializes it.
local coreActor, coreCreateErr = registry:Ensure({
    actorId = "npc:core-world:1",
    ownerMod = "PsychopatzCore",
    displayName = "Core World Survivor",
    archetypeID = "core.survivor",
    world = { location = { position = { x = 50, y = 60, z = 0 } } },
})
T.truthy(coreActor, coreCreateErr)
local acqActor, acqErr = registry:AcquireProvider("npc:core-world:1", {
    provider = "PsychopatzCore",
    owner = "PsychopatzCore:world",
    authority = "server",
    now = 1,
})
T.truthy(acqActor, acqErr)
local promotedRecord = {
    id = "npc:core-world:1",
    coreActorID = "npc:core-world:1",
    coreBacked = true,
    presenceState = PNC.Const.PRESENCE_LIVE,
    runtime = { coreActorID = "npc:core-world:1" },
}
local swBody = { getPersistentOutfitID = function() return 999999 end }
local swOk, swReason = Adapter.SyncPresenceLease(
    promotedRecord, swBody, PsychopatzCore, { now = 16 }
)
T.truthy(swOk, swReason)
local switched = registry:Get("npc:core-world:1")
T.equal(switched.providerLease.provider, "ProjectHoomans",
    "live materialization switches abstract Core actor to ProjectHoomans")
T.equal(switched.providerLease.state, "materialized",
    "switched Core actor lease is materialized")
T.equal(switched.providerLease.bodyID, "999999",
    "switched Core actor lease records bodyID")

T.finish("pnc_presence_core_lease_sync_smoke")
