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
T.equal(record.equipment.worn.Torso_Upper, "Base.Tshirt_DefaultTEXTURE_TINT",
    "untouched generated NPC retains its starter shirt")

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

local appearance = PNC.Identity.Appearance
local exclusive = appearance.AreExclusive
appearance.AreExclusive = function(first, second)
    return first == "SweaterHat" and second == "Hat"
end
local ledger = assert(ActorInventory.CreateBaselineFromPayload(actor.personalInventory))
local hat = assert(ledger:Add({ itemId = "a:hat", fullType = "Base.Hat_BaseballCap" }))
local hood = assert(ledger:Add({ itemId = "b:hood", fullType = "Base.HoodieUP_WhiteTINT" }))
assert(ledger:SetEquipmentState({ worn = { Hat = hat.itemId, SweaterHat = hood.itemId } }))
local conflictingActor = { personalInventory = assert(ledger:ToPayload("BASELINE_DELTA")) }
local inventory = assert(Bridge.HydrateRecord(rehydratedRecord, conflictingActor))
T.truthy(inventory.items[hat.itemId], "exclusive hat survives reload")
T.equal(inventory.items[hat.itemId].wornSlot, nil, "hat is carried loose after reload")
T.equal(inventory.worn.SweaterHat, hood.itemId, "hood stays worn")
local revision = inventory.revision
local worn, reason = PNC.Inventory.SetWorn(rehydratedRecord, hat.itemId, "Hat")
T.falsy(worn, "a manual wear request respects the current outfit")
T.equal(reason, "worn_slot_conflict")
T.equal(inventory.revision, revision, "a conflicting action produces no inventory mutation")
local repaired, mode = Bridge.CaptureRecord(rehydratedRecord, conflictingActor)
T.equal(mode, "BASELINE_DELTA", "conflict resolution retains compact persistence")
local restored = assert(ActorInventory.Decode(repaired))
T.truthy(restored:Get(hat.itemId), "unequipped item is saved with its inventory ID")
T.equal(restored.equipment.worn.Hat, nil, "unequipped item has no saved wear assignment")
T.equal(restored.equipment.worn.SweaterHat, hood.itemId, "compatible outfit state is saved")
appearance.AreExclusive = exclusive

T.finish("pnc_actor_inventory_bridge_smoke")
