local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
local Core = require "PsychopatzCore/Actors/PsychopatzActors"
local HoomansProvider = PNC.Persistence.CoreProvider
local dtRepository = os.getenv("PZ_TEST_DT_REPOSITORY")
    or "../DynamicTrading"

DTHoomans = {}
local DTProvider = dofile(dtRepository
    .. "/Contents/mods/DTHoomans/42.20/media/lua/shared/DTHoomans/"
    .. "DTHoomans_CoreProvider.lua")
DTAbstract = {}
local AbstractProvider = dofile(dtRepository
    .. "/Contents/mods/DTAbstract/42.20/media/lua/shared/DTAbstract/"
    .. "DTAbstract_CoreProvider.lua")

DTCommon = {
    TraderStock = {
        EncodeItem = function(fullType, quantity)
            return { fullType = fullType, quantity = quantity }
        end,
    },
    DEFAULT_STOCK = {},
}
local Policy = dofile(dtRepository
    .. "/Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/"
    .. "DTCommon_CoreActorPolicy.lua")

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local registry = Core.NewRegistry()
local actor, actorReason = registry:Create({
    actorId = "npc:p9:combined",
    identitySeed = "p9-combined-seed",
    social = {
        relationships = {
            ["player:user:alice"] = {
                target = "player:user:alice",
                approval = 55,
                respect = 25,
                familiarity = 20,
            },
        },
    },
    world = { position = { x = 40, y = 41, z = 0 } },
})
truthy(actor, actorReason)
truthy(Core.DefaultRegistry:Register(actor),
    "combined Core actor default registry projection")

local function sync(updated)
    local current = registry:Get(actor.actorId)
    local committed, reason = registry:Commit(actor.actorId, {
        providerLease = updated.providerLease,
    }, current.revision)
    truthy(committed, reason)
    return registry:Get(actor.actorId)
end

local leased, leaseReason = HoomansProvider.Acquire(actor, PsychopatzCore, {
    owner = "ProjectHoomans:p9",
    authority = "server",
    now = 1,
})
truthy(leased, leaseReason)
actor = sync(leased)

local body = { bodyID = "body:p9:combined" }
local bodyConfigured = false
local materialized, materializeReason = HoomansProvider.Materialize(
    actor, PsychopatzCore, {
        owner = "ProjectHoomans:p9",
        authority = "server",
        now = 2,
        lifecycle = {
            SpawnLiveBody = function()
                return body, "p9-fixture"
            end,
            StampLiveBody = function(record, spawned)
                bodyConfigured = record.runtime.bodyLease ~= nil
                    and spawned == body
            end,
        },
        applyProjection = function(spawned, projection, record)
            return spawned == body
                and projection.identity.identitySeed
                    == record.identity.identitySeed
                and projection.appearance.contract.policyHash
                    == record.appearance.contract.policyHash
        end,
    }
)
truthy(materialized, materializeReason)
truthy(bodyConfigured, "combined body lease configuration")
actor = sync(materialized.actor)

local record = {
    ca = Policy.New({
        actorID = actor.actorId,
        providerLease = actor.providerLease,
        relationshipPricing = true,
        restockItems = { { fullType = "Base.Bandage", quantity = 2 } },
    }),
}
local stock = { records = {} }
function stock:add(item)
    self.records[#self.records + 1] = item
    return true
end
local restocked, restockReason = Policy.Restock(record, stock, {
    authority = "server",
    atSettlement = true,
    earned = true,
    now = 24,
})
truthy(restocked, restockReason)
equal(#stock.records, 1, "combined DT stock exists")
equal(#actor.personalInventory.items, 3,
    "merchant stock does not enter personal inventory")
local pricing = Policy.PriceContext(record, {
    getUsername = function() return "alice" end,
})
truthy(pricing.relationshipModifier > 0,
    "combined relationship pricing reads Core social")
equal(record.ca.provider, "DTHoomans", "DT records provider lease")

local dematerialized, dematerializeReason = HoomansProvider.Dematerialize(
    actor, PsychopatzCore, {
        owner = "ProjectHoomans:p9",
        authority = "server",
        body = body,
        removeBody = function(record, removedBody)
            return record.runtime.bodyLease ~= nil and removedBody == body
        end,
        now = 25,
    }
)
truthy(dematerialized, dematerializeReason)
actor = sync(dematerialized.actor)
equal(actor.providerLease.state, "abstract", "combined body release")

local released, releaseReason = HoomansProvider.Release(actor, PsychopatzCore, {
    owner = "ProjectHoomans:p9",
    authority = "server",
    now = 26,
})
truthy(released, releaseReason)
actor = sync(released)
local abstract, abstractReason = AbstractProvider.Acquire(actor, PsychopatzCore, {
    owner = "DTAbstract:p9",
    authority = "server",
    now = 27,
})
truthy(abstract, abstractReason)
local abstractProjection, projectionReason = AbstractProvider.Project(
    abstract, PsychopatzCore)
truthy(abstractProjection, projectionReason)
actor = sync(abstract)
equal(abstractProjection.identity.identitySeed,
    actor.identity.identitySeed, "abstract provider identity continuity")
equal(abstractProjection.personalInventory.items[1].itemId,
    actor.personalInventory.items[1].itemId,
    "abstract provider inventory continuity")

local finalActor, finalReason = AbstractProvider.Release(abstract,
    PsychopatzCore, {
        owner = "DTAbstract:p9",
        authority = "server",
        now = 28,
    })
truthy(finalActor, finalReason)
actor = sync(finalActor)
local saved = registry:Save()
truthy(saved, "combined save")
local fresh = Core.NewRegistry()
truthy(fresh:Load(saved), "combined reload")
local restored = fresh:Get(actor.actorId)
equal(restored.providerLease.state, "released", "combined reload lease")
equal(restored.identity.identitySeed, actor.identity.identitySeed,
    "combined reload identity")
equal(restored.social.relationships["player:user:alice"].respect,
    actor.social.relationships["player:user:alice"].respect,
    "combined reload social")

T.finish("pnc_npc_foundation_end_to_end_smoke")
