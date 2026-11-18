local T = require "tests/support/test"
T.addPackagePaths()
PNC = { Identity = {} }
require "PNC/Core/Identity/PNC_Identity_Appearance"
local Edits = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringLoadout"
local draft = { appearance = { outfit = { mode = "none" }, slots = {} }, startingItems = {} }
T.truthy(Edits.SetSlot(draft, { kind = "worn", id = "Shirt" },
    { type = "Base.Shirt", itemState = { visualTextureChoice = 3 } }), "clothing authors appearance")
T.equal(draft.appearance.slots.Shirt.type, "Base.Shirt", "clothing slot remains canonical appearance")
T.falsy(draft.authoringClears and draft.authoringClears.startingItems,
    "clothing alone does not clear unrelated inventory intent")
T.truthy(Edits.SetSlot(draft, { kind = "worn", id = "Back" },
    { type = "Base.Bag", maxWeight = 20, wearableSlot = "Back" }), "bag selection")
T.equal(#draft.startingItems, 1, "bag belongs to startingItems rather than cosmetic clothing")
T.equal(draft.startingItems[1].wornSlot, "Back", "bag owns its wearable slot")
T.equal(draft.startingItems[1].maxWeight, 20, "bag retains its container capacity")
T.truthy(Edits.SetSlot(draft, { kind = "worn", id = "Back" }), "clear bag slot")
T.equal(#draft.startingItems, 0, "clearing bag removes inventory representation too")
T.equal(draft.appearance.slots.Back.mode, "none", "cleared bag cannot regenerate through appearance")
local full = { appearance = { outfit = { mode = "item", id = "Police" } }, startingItems = {} }
for i = 1, 128 do full.startingItems[i] = { type = "Base.Item", key = tostring(i) } end
local before = full.appearance
T.falsy(Edits.SetSlot(full, { kind = "worn", id = "Back" },
    { type = "Base.Bag", maxWeight = 20 }), "inventory limit rejects bag")
T.equal(full.appearance, before, "rejection leaves original appearance object untouched")
T.equal(full.appearance.outfit.id, "Police", "rejection cannot partially clear outfit")
T.equal(#full.startingItems, 128, "rejection leaves inventory intact")
local imported = { startingItems = { { type = "Base.Axe" }, { type = "Base.WaterBottle" } } }
T.truthy(Edits.SetSlot(imported, { kind = "item", id = "item:2", index = 2 }), "imported keyless item can be removed")
T.equal(#imported.startingItems, 1, "removal affects only selected keyless item")
T.equal(imported.startingItems[1].type, "Base.Axe", "other imported items survive")
T.finish("pnc_npc_authoring_loadout_smoke")
