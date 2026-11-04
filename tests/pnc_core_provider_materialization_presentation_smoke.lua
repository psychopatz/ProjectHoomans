local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
local Core = require "PsychopatzCore/Actors/PsychopatzActors"
T.load("ProjectHoomans", "shared", "PNC/Core/Persistence/PNC_Persistence_CoreProvider.lua")

local Adapter = PNC.Persistence.CoreProvider
local registry = Core.NewRegistry()
local actor, actorReason = registry:Create({
    actorId = "npc:core-provider:presentation",
    identitySeed = "core-provider-presentation-seed",
    world = { position = { x = 20, y = 21, z = 0 } },
})
T.truthy(actor, actorReason)

actor.providerLease = {
    leaseID = "lease:abstract",
    provider = "DTHoomans",
    state = "abstract",
}

local animationCalls = 0
local visualCalls = 0
local equipmentCalls = 0
local inventoryCalls = 0

PNC.Animation = PNC.Animation or {}
PNC.Animation.ApplyLiveSetup = function(body, record)
    animationCalls = animationCalls + 1
    T.equal(body.bodyID, "body:core-provider:presentation")
    T.equal(record.id, actor.actorId)
end

PNC.Visuals = PNC.Visuals or {}
PNC.Visuals.ApplyHumanVisuals = function(body, record)
    visualCalls = visualCalls + 1
    T.equal(body.bodyID, "body:core-provider:presentation")
    T.equal(record.id, actor.actorId)
end

PNC.Equipment = PNC.Equipment or {}
PNC.Equipment.Apply = function(body, record)
    equipmentCalls = equipmentCalls + 1
    T.equal(body.bodyID, "body:core-provider:presentation")
    T.equal(record.id, actor.actorId)
    return true, "presentation_fixture"
end

PNC.Inventory = PNC.Inventory or {}
PNC.Inventory.MaterializeLooseInventory = function(record, body)
    inventoryCalls = inventoryCalls + 1
    T.equal(body.bodyID, "body:core-provider:presentation")
    T.equal(record.id, actor.actorId)
    return true, "inventory_fixture"
end

local body = {
    bodyID = "body:core-provider:presentation",
    getInventory = function()
        return {}
    end,
}

local service = {}
function service.Project(source)
    return source
end
function service.Materialize(source)
    local nextActor = {}
    for key, value in pairs(source) do
        nextActor[key] = value
    end
    nextActor.providerLease = {
        leaseID = "lease:materialized",
        provider = "DTHoomans",
        state = "materialized",
        bodyID = body.bodyID,
    }
    return nextActor
end

local result, reason = Adapter.Materialize(actor, {
    Actors = { Provider = service },
}, {
    lifecycle = {
        SpawnLiveBody = function()
            return body, "presentation_fixture"
        end,
        StampLiveBody = function() end,
    },
    applyProjection = function(spawned)
        return spawned == body
    end,
})

T.truthy(result, reason)
T.equal(animationCalls, 1, "CoreProvider applies live animation setup")
T.equal(visualCalls, 1, "CoreProvider applies canonical human visuals")
T.equal(equipmentCalls, 1, "CoreProvider applies canonical equipment")
T.equal(inventoryCalls, 1, "CoreProvider hydrates physical inventory once")

T.finish("pnc_core_provider_materialization_presentation_smoke")
