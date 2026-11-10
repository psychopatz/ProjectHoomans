local T = require "tests/support/test"

T.addPackagePaths()
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local registry = Actors.NewRegistry()
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Actors = Actors
PsychopatzCore.Actors.DefaultRegistry = registry

PNC = PNC or {}
PNC.Registry = {
    MarkDirty = function() end,
}
PNC.Persistence = PNC.Persistence or {}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Persistence/PNC_Persistence_CoreProvider.lua")

local Adapter = PNC.Persistence.CoreProvider
local record = {
    id = "npc:adoption:test",
    name = "Adoption Test",
    identitySeed = "adoption-test-seed",
    archetypeID = "core.survivor",
    x = 101,
    y = 202,
    z = 0,
    runtime = {},
}

local actor, reason = Adapter.EnsureActor(record, PsychopatzCore)
T.truthy(actor, reason)
T.equal(record.coreActorID, "npc:adoption:test",
    "adopter record receives canonical actor ID")
T.equal(record.runtime.coreActorID, "npc:adoption:test",
    "runtime record receives canonical actor ID")
local canonical = registry:Get("npc:adoption:test")
T.equal(canonical.providerLease.provider, "ProjectHoomans",
    "released adopter is claimed by the shared abstract provider")
T.equal(canonical.providerLease.state, "abstract",
    "adopter never leaves a released map actor")
T.equal(record.presenceState, PNC.Const.PRESENCE_ABSTRACT,
    "adopter record mirrors Core abstract presence")
T.equal(registry:Count(), 1, "adoption creates one canonical actor")

local second, secondReason = Adapter.EnsureActor(record, PsychopatzCore)
T.truthy(second, secondReason)
T.equal(registry:Count(), 1,
    "repeated adoption does not duplicate the canonical actor")

T.finish("pnc_core_actor_adoption_smoke")
