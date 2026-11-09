local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
local Core = require "PsychopatzCore/Actors/PsychopatzActors"
local Adapter = PNC.Persistence.CoreProvider

local registry = Core.NewRegistry()
local previousDefault = Core.DefaultRegistry
Core.DefaultRegistry = registry
PsychopatzCore.Actors = Core

local actor, actorReason = registry:Create({
    actorId = "dt:legacy:member:1",
    identitySeed = "dt-legacy-member-seed",
    providerLease = {
        provider = "DTHoomans",
        owner = "DynamicTrading",
        state = "abstract",
    },
    world = { position = { x = 44, y = 55, z = 0 } },
})
T.truthy(actor, actorReason)

local dirty = 0
local previousMarkDirty = PNC.Registry.MarkDirty
PNC.Registry.MarkDirty = function()
    dirty = dirty + 1
    return true
end

local record = {
    id = "npc:legacy:member:1",
    coreActorID = actor.actorId,
    runtime = {},
    factionID = "faction:legacy:trader",
    factionName = "Legacy Road Traders",
    factionArchetypeID = "trader",
    factionRole = "trader",
}
local reconciled, reason = Adapter.AnnotateExistingCoreRecord(
    record,
    PsychopatzCore
)
T.truthy(reconciled, reason)
T.equal(record.coreActorID, actor.actorId,
    "reconcile changed the canonical Core actor ID")
T.equal(record.runtime.coreActorID, actor.actorId,
    "reconcile did not persist the runtime Core actor reference")

local updated = registry:Get(actor.actorId)
local identity = updated.extensions
    and updated.extensions["PsychopatzCore.ActorIdentity"] or nil
local affiliation = updated.extensions
    and updated.extensions["PsychopatzCore.SurvivorWorld"] or nil
T.truthy(identity and identity.project == true,
    "reconcile did not add the Core projection hint")
T.truthy(identity and identity.providerID == "DTHoomans",
    "reconcile did not preserve the provider identity")
T.truthy(affiliation and affiliation.factionID == "faction:legacy:trader",
    "reconcile did not carry Hoomans faction affiliation to Core")
T.equal(dirty, 1, "reconcile did not mark the durable Hoomans record dirty")

PNC.Registry.MarkDirty = previousMarkDirty
Core.DefaultRegistry = previousDefault

T.finish("pnc_core_provider_identity_reconcile_smoke")
