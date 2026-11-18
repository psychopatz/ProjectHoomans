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
local clothed = { appearance = { outfit = { mode = "random" }, slots = {} }, startingItems = {} }
local baseline = { inventory = { items = {
    shirt = { type = "Base.Shirt", wornSlot = "Shirt", itemState = { visualTextureChoice = 4 } },
    pants = { type = "Base.Pants", wornSlot = "Pants", itemState = { visualColorR = 0.3 } },
} } }
T.truthy(Edits.SetSlot(clothed, { kind = "worn", id = "Shirt" }, { type = "Base.NewShirt" }, baseline), "single-slot replacement")
T.equal(clothed.appearance.slots.Pants.type, "Base.Pants", "unrelated clothing stays equipped")
T.equal(clothed.appearance.slots.Pants.itemState.visualColorR, 0.3, "unrelated exact item visual state is preserved")
local dressed = 0
local native = { type = "Base.NamedShirt", itemState = { visualTextureChoice = 7 } }
PNC.Inventory = { CaptureNativeItem = function(item) return item end }
SurvivorDesc = { new = function(register)
    T.equal(register, false, "preset capture uses an unregistered preview descriptor")
    local selected
    return {
        setFemale = function(_, female) T.equal(female, true, "preset capture applies selected gender") end,
        dressInNamedOutfit = function(_, id) selected = id; dressed = dressed + 1 end,
        getWornItems = function() return {
            size = function() return selected == "ValidOutfit" and 1 or 0 end,
            getItemByIndex = function() return native end,
            getLocation = function() return setmetatable({}, { __tostring = function() return "base:shirt" end }) end,
        } end,
    }
end }
local captured = Edits.CaptureOutfit("ValidOutfit", true)
T.equal(captured["base:shirt"].type, "Base.NamedShirt", "native preset becomes ordinary canonical slots")
T.equal(captured["base:shirt"].itemState.visualTextureChoice, 7, "selected native visual choice is captured exactly")
T.truthy(captured["base:shirt"].itemState ~= native.itemState, "captured visual state is detached")
T.equal(dressed, 1, "one native preset capture per explicit choice")
T.falsy(Edits.CaptureOutfit("MissingOutfit", true), "unavailable preset produces a normal rejection")
T.finish("pnc_npc_authoring_loadout_smoke")
