local T = require "tests/support/test"

-- Reuse the source-backed P0A setup.  This loads the real Hoomans identity,
-- appearance, inventory, relationship, and persistence modules before the
-- focused P0B characterizations below.
T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")

local function newRecord(id)
    return PNC.Types.NewRecord({
        id = id,
        displayName = "Parity Merchant",
        identitySeed = 731,
        archetypeID = "parity_merchant",
        tacticalClass = "neutral",
        x = 104.5,
        y = 208.25,
        z = 0,
        anchorX = 100,
        anchorY = 200,
        anchorZ = 0,
        equipment = { worn = {}, attached = {} },
    })
end

-- The authored policy is valid input to the appearance normalizer, but it is
-- not accepted by the current record definition or persistence serializer.
local authoredPolicy = {
    schemaVersion = 2,
    outfit = "none",
    slots = {
        Torso_Upper = {
            mode = "item",
            type = "Base.Jacket",
            wornSlot = "Torso_Upper",
            itemState = { modData = { source = "authored" } },
        },
    },
}
local authored = newRecord("npc:p0b:appearance")
authored.appearance = authoredPolicy
local authoredPayload = PNC.Persistence.SerializeRecord(authored)
T.equal(authoredPayload.appearance, nil,
    "authored appearance policy was unexpectedly serialized")
local restoredAuthored = PNC.Persistence.DeserializeRecord(
    authoredPayload, authored.id)
T.truthy(restoredAuthored, "authored appearance record rejected")
T.equal(restoredAuthored.appearance, nil,
    "authored appearance policy was unexpectedly restored")

-- SurvivorFactory resolves all four voice values, while the current identity
-- sanitizer persists only the legacy voice string.
local voiced = newRecord("npc:p0b:voice")
local sourceVoice = voiced.identity.survivor
T.equal(sourceVoice.voice, "parity_voice", "factory voice")
T.equal(sourceVoice.voicePrefix, "parity_voice", "factory voice prefix")
T.equal(sourceVoice.voiceType, 3, "factory voice type")
T.near(sourceVoice.voicePitch, 1.25, 0.000001, "factory voice pitch")
local voicePayload = PNC.Persistence.SerializeRecord(voiced)
local persistedVoice = voicePayload.identity.survivor
T.equal(persistedVoice.voice, "parity_voice", "legacy voice persistence")
T.equal(persistedVoice.voicePrefix, nil,
    "voice prefix unexpectedly persisted")
T.equal(persistedVoice.voiceType, nil, "voice type unexpectedly persisted")
T.equal(persistedVoice.voicePitch, nil, "voice pitch unexpectedly persisted")

-- Exercise the real Hoomans -> Core virtual inventory bridge.  Custom names
-- are a first-class item field; portable modData remains itemState data.
local inventoryRecord = newRecord("npc:p0b:item-state")
T.truthy(PNC.Inventory.CreateFromTemplate(inventoryRecord),
    "inventory template creation")
T.truthy(PNC.Inventory.ApplyDelta(inventoryRecord, {
    {
        op = "add",
        item = {
            id = "loot:p0b:01",
            type = "Base.CustomLoot",
            stack = 1,
            container = "root",
            customName = "Ledger",
            legacyTemplateKey = "legacy:p0b:item",
            itemState = { modData = { source = "p0b" } },
        },
    },
}, "p0b_item_state"), "item-state mutation")
local beforeItem = inventoryRecord.inventory.items["loot:p0b:01"]
T.equal(beforeItem.customName, "Ledger", "source custom name")
T.equal(beforeItem.legacyTemplateKey, "legacy:p0b:item",
    "source legacy template key")
T.equal(beforeItem.itemState.modData.source, "p0b", "source modData")
local inventoryPayload = PNC.Inventory.Serialize(inventoryRecord)
T.truthy(inventoryPayload, "inventory payload")
T.equal(inventoryPayload[2], "BASELINE_DELTA",
    "item-state fixture unexpectedly changed persistence mode")
local legacyDelta
for i = 1, #(inventoryPayload[5] and inventoryPayload[5][3] or {}) do
    local candidate = inventoryPayload[5][3][i]
    if candidate[3] and candidate[3][1] == "loot:p0b:01" then
        legacyDelta = candidate
        break
    end
end
T.truthy(legacyDelta, "legacy item delta missing")
T.equal(legacyDelta[4], 2, "delta metadata schema was not versioned")
local restoredInventoryRecord = newRecord("npc:p0b:item-state")
T.truthy(PNC.Inventory.Deserialize(restoredInventoryRecord, inventoryPayload),
    "inventory payload rehydration")
local afterItem = restoredInventoryRecord.inventory.items["loot:p0b:01"]
T.truthy(afterItem, "portable item missing after rehydration")
T.equal(afterItem.customName, "Ledger", "custom name changed")
T.equal(afterItem.legacyTemplateKey, "legacy:p0b:item",
    "legacy template key changed")
T.equal(afterItem.itemState.modData.source, "p0b", "modData changed")

-- The FULL bridge uses the same versioned metadata contract, so the exact
-- item state is not dependent on delta mode.
local fullRecord = newRecord("npc:p0b:item-state-full")
T.truthy(PNC.Inventory.CreateFromTemplate(fullRecord),
    "full inventory template creation")
T.truthy(PNC.Inventory.ApplyDelta(fullRecord, {
    {
        op = "add",
        item = {
            id = "loot:p0b:full",
            type = "Base.CustomLoot",
            stack = 1,
            container = "root",
            legacyTemplateKey = "legacy:p0b:full",
            itemState = { modData = { source = "full" } },
        },
    },
}, "p0b_item_state_full"), "full item-state mutation")
fullRecord.inventoryPersistenceMode = "FULL"
local fullPayload = PNC.Inventory.Serialize(fullRecord)
T.equal(fullPayload[2], "FULL", "full inventory mode changed")
T.equal(fullPayload[3][5], 2, "full metadata schema was not versioned")
local restoredFullRecord = newRecord("npc:p0b:item-state-full")
T.truthy(PNC.Inventory.Deserialize(restoredFullRecord, fullPayload),
    "full inventory payload rehydration")
T.equal(restoredFullRecord.inventory.items["loot:p0b:full"].legacyTemplateKey,
    "legacy:p0b:full", "full legacy template key changed")

T.finish("pnc_npc_foundation_p0b_gap_characterization_smoke")
