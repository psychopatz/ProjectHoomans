local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
local Core = require "PsychopatzCore/Actors/PsychopatzActors"
local Adapter = PNC.Persistence.CoreProvider
local registry = Core.NewRegistry()
local actor, actorReason = registry:Create({
    actorId = "npc:p8:hoomans-provider",
    identitySeed = "p8-hoomans-provider-seed",
    persona = { backstory = { selections = {
        hometown = { id = "hometown.rosewood", version = 1 },
    } } },
    social = {
        relationships = {
            ["player:user:alice"] = {
                target = "player:user:alice",
                approval = 31,
                respect = 17,
                familiarity = 9,
            },
        },
    },
    world = { position = { x = 12, y = 13, z = 0 } },
})
T.truthy(actor, actorReason)
T.truthy(Adapter, "Core provider adapter missing")
T.truthy(actor.persona and actor.persona.backstory,
    "provider source persona")

local leased, leaseReason = Adapter.Acquire(actor, PsychopatzCore, {
    owner = "ProjectHoomans:presence",
    now = 1,
})
T.truthy(leased, leaseReason)
T.equal(leased.providerLease.provider, "DTHoomans", "Hoomans provider")

local body = { bodyID = "body:p8:hoomans" }
local stamped = false
local removed = false
local applied = false
local lifecycle = {
    SpawnLiveBody = function()
        return body, "fixture"
    end,
    StampLiveBody = function(record, spawned)
        stamped = record.runtime.bodyLease ~= nil and spawned == body
    end,
}
local materialized, materializeReason = Adapter.Materialize(
    leased, PsychopatzCore, {
        owner = "ProjectHoomans:presence",
        lifecycle = lifecycle,
        applyProjection = function(spawned, projection, record)
            applied = spawned == body
                and projection.identity.identitySeed
                    == record.identity.identitySeed
                and projection.appearance.contract.policyHash
                    == record.appearance.contract.policyHash
                and projection.personalInventory.items[1].itemId
                    == record.personalInventory.items[1].itemId
                and projection.social.relationships["player:user:alice"].approval
                    == record.social.relationships["player:user:alice"].approval
            return applied
        end,
        now = 2,
    }
)
T.truthy(materialized, materializeReason)
T.truthy(applied, "Core appearance, inventory, and social projection")
T.equal(materialized.projection.persona.backstory.selections.hometown.id,
    "hometown.rosewood", "Core persona provider projection")
T.equal(materialized.projection.knowledge.schemaVersion, 1,
    "Core Knowledge provider projection")
T.truthy(stamped, "Hoomans body receives Core lease")
T.equal(materialized.record.runtime.bodyLease,
    materialized.leaseID, "body and Core lease identity")

local dematerialized, dematerializeReason = Adapter.Dematerialize(
    materialized.actor, PsychopatzCore, {
        owner = "ProjectHoomans:presence",
        body = body,
        removeBody = function(record, removedBody)
            removed = record.runtime.bodyLease ~= nil and removedBody == body
            return removed
        end,
        now = 3,
    }
)
T.truthy(dematerialized, dematerializeReason)
T.truthy(removed, "Hoomans body release boundary")
T.equal(dematerialized.actor.providerLease.state, "abstract",
    "Hoomans dematerializes through Core")
T.equal(dematerialized.actor.appearance.contract.policyHash,
    actor.appearance.contract.policyHash, "appearance parity")
T.equal(dematerialized.actor.personalInventory.items[1].itemId,
    actor.personalInventory.items[1].itemId, "inventory parity")
T.equal(dematerialized.actor.social.relationships["player:user:alice"].respect,
    actor.social.relationships["player:user:alice"].respect, "social parity")

local payload = registry:Save()
T.truthy(payload, "provider source registry save")
local fresh = Core.NewRegistry()
T.truthy(fresh:Load(payload), "provider source registry reload")
local restored = fresh:Get(actor.actorId)
T.equal(restored.providerLease.state, "released",
    "original registry remains independent")

T.finish("pnc_npc_foundation_core_provider_smoke")
