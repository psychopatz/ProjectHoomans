local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local Core = require "PsychopatzCore/Actors/PsychopatzActors"
local ActorInventory = Core.Inventory
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local Bridge = PNC.Inventory.ActorInventoryBridge
    or require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_ActorBridge"

local function itemIDs(payload)
    local ledger, reason = ActorInventory.Decode(payload)
    T.truthy(ledger, reason)
    local output = {}
    for _, entry in ipairs(ledger:List()) do
        output[#output + 1] = entry.itemId
    end
    table.sort(output)
    return output
end

local function hasID(values, expected)
    for _, value in ipairs(values) do
        if value == expected then return true end
    end
    return false
end

local registry = Core.NewRegistry()
local actor, reason = registry:Create({
    actorId = "npc:actor-inventory-bridge",
    identitySeed = "actor-inventory-bridge-seed",
    archetypeID = "General",
})
T.truthy(actor, reason)
T.equal(actor.personalInventory.mode, "SEED_ONLY",
    "fixture starts compact")

local record = PNC.Types.NewRecord({
    id = actor.actorId,
    displayName = actor.identity.displayName,
    identitySeed = actor.identity.identitySeed,
    identity = actor.identity,
    appearance = actor.appearance,
    archetypeID = "General",
    x = 10, y = 20, z = 0,
    persist = true,
})
T.truthy(record, "Hoomans record fixture")

local hydrated, sourceMode = Bridge.HydrateRecord(record, actor)
T.truthy(hydrated, sourceMode)
T.equal(sourceMode, "SEED_ONLY", "seed-only source hydrated")
T.equal(record.runtime.coreInventoryHydrated, true,
    "Core inventory hydration marker")
T.equal(PNC.Inventory.Internal.countMapEntries(record.inventory.items), 3,
    "deterministic Core baseline hydrated into Hoomans inventory")

local unchanged, unchangedMode, unchangedReason =
    Bridge.CaptureRecord(record, actor)
T.truthy(unchanged, unchangedReason)
T.equal(unchangedMode, "SEED_ONLY",
    "unchanged physical/logical inventory collapses to seed-only")

local foundID = actor.actorId .. ":found:bandage"
local added, addReason = PNC.Inventory.AddItems(record, {
    {
        id = foundID,
        type = "Base.Bandage",
        stack = 1,
        origin = "world",
    },
}, "root", "actor_bridge_fixture_add")
T.truthy(added, addReason)

local changed, changedMode, changedReason =
    Bridge.CaptureRecord(record, actor)
T.truthy(changed, changedReason)
T.equal(changedMode, "BASELINE_DELTA",
    "durable physical change becomes baseline delta")
T.truthy(hasID(itemIDs(changed), foundID),
    "durable added item captured by exact item ID")

local changedActor = {}
for key, value in pairs(actor) do changedActor[key] = value end
changedActor.personalInventory = changed

local rehydratedRecord = PNC.Types.NewRecord({
    id = actor.actorId,
    displayName = actor.identity.displayName,
    identitySeed = actor.identity.identitySeed,
    identity = actor.identity,
    appearance = actor.appearance,
    archetypeID = "General",
    x = 10, y = 20, z = 0,
    persist = true,
})
T.truthy(Bridge.HydrateRecord(rehydratedRecord, changedActor),
    "delta rehydrates")
T.truthy(rehydratedRecord.inventory.items[foundID],
    "delta item restored into Hoomans logical inventory")

local repeated, repeatedMode, repeatedReason =
    Bridge.CaptureRecord(rehydratedRecord, changedActor)
T.truthy(repeated, repeatedReason)
T.equal(repeatedMode, "BASELINE_DELTA",
    "repeated capture remains delta")
T.truthy(hasID(itemIDs(repeated), foundID),
    "repeated capture preserves durable item")

local firstBytes = #assert(Json.Encode(changed))
local repeatedBytes = #assert(Json.Encode(repeated))
T.truthy(repeatedBytes <= firstBytes + 64,
    "repeated capture does not accumulate historical delta bloat")

T.finish("pnc_actor_inventory_bridge_smoke")
