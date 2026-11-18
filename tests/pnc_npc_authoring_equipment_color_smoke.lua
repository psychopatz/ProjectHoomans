local F = require("tests/support/pnc_authoring_session")()
local T, Model, copy = F.T, F.Model, F.copy

-- Use the production visual codec, preview model and inventory projection;
-- replace native item creation and template generation at their boundaries.
T.load("ProjectHoomans", "shared", "PNC/Core/Equipment/PNC_Equipment_Slots/VisualNormalization.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Equipment/PNC_Equipment_Slots/VisualCapture.lua")
PNC.Equipment.NormalizeLoadoutSpec = function(source)
    local result = copy(source or {})
    result.wornVisuals = result.wornVisuals or {}
    return result
end
PNC.Inventory.Internal = { normalizeLegacyBagSlot = function() end }
T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/Equipment/PNC_Inventory_EquipmentSync.lua")

local creations, rebuilds = 0, 0
PNC.Equipment.CreateItem = function()
    creations = creations + 1
    local shade = creations / 10
    local tint = {
        getRedFloat = function() return shade end,
        getGreenFloat = function() return .4 end,
        getBlueFloat = function() return .6 end,
    }
    local visual = {
        getTint = function() return tint end,
        getBaseTexture = function() return creations end,
        getTextureChoice = function() return 2 end,
        getDecal = function() return "BagDecal" end,
    }
    return { getVisual = function() return visual end,
        getClothingItem = function() return {} end }
end
local bagType, bagKey, explicitState = "Base.Bag_DuffelBag", "tmpl:bag:0", nil
PNC.Inventory.CreateFromTemplate = function(record)
    rebuilds = rebuilds + 1
    local id = "bag:" .. rebuilds
    record.inventory = {
        items = { [id] = { id = id, type = bagType, templateKey = bagKey,
            wornSlot = "Back", maxWeight = 20,
            itemState = copy(explicitState or { condition = 8, modData = { kept = true } }) } },
        worn = { Back = id }, equipped = {}, attached = {}, containers = {},
    }
    PNC.Inventory.SyncEquipmentFromInventory(record)
    return record.inventory
end
PNC.Inventory.EnsureRecordInventory = PNC.Inventory.CreateFromTemplate
PNC.UniqueNPCs.Resolve = function(def, options)
    local record = copy(def)
    record.identitySeed = options.identitySeed
    return record
end
PNC.Identity.RollAppearance = function() end
PNC.Identity.BuildPortraitSummary = nil

local draft = Model.FromDefinition({
    displayName = "Alex Survivor", isFemale = false, equipmentSpawnMode = "none",
    identity = { survivor = { forename = "Alex", surname = "Survivor" } },
    appearance = { outfit = { mode = "none" } },
}, { previewSeed = 42 })
local function bag()
    local inventory = draft.runtimeRecord.inventory
    return inventory.items[inventory.worn.Back]
end
local function portrait()
    return Model.BuildPortraitSpec(draft).equipment.wornVisuals.Back
end
local initial = portrait()
T.near(initial.tint.r, .1, .0001, "first native bag tint captured")
local firstID = bag().id

draft.identity.survivor.forename = "Robin"
draft.displayName = "Robin Survivor"
T.near(portrait().tint.r, initial.tint.r, .0001, "name edit retains tint")
draft.appearance.voice = { mode = "item", prefix = "James", type = 0, pitch = 30 }
T.near(portrait().tint.r, initial.tint.r, .0001, "pitch edit retains tint")
T.equal(creations, 1, "scalar edits do not create another native backpack")
draft.identity.survivor.skinTexture = "MaleBody03"
draft.identity.survivor.hairModel = "Short"
T.near(portrait().tint.r, initial.tint.r, .0001, "skin/hair edits retain backpack tint")

draft.startingItems = { { type = "Base.Money", stack = 10, key = "money" } }
draft.authoredFields.startingItems = true
local carriedID = bag().id
T.near(portrait().tint.r, initial.tint.r, .0001, "carried-item edit preserves backpack color")
T.truthy(bag().id ~= carriedID, "carried-item edit rebuilds the inventory")
draft.startingItems = {}

-- A different outfit policy rebuilds inventory, including the archetype bag.
draft.appearance.outfit = { mode = "random" }
local rebuilt = portrait()
T.truthy(bag().id ~= firstID, "regression exercises a newly allocated inventory item")
T.near(rebuilt.tint.r, initial.tint.r, .0001, "inventory rebuild preserves bag color")
T.equal(rebuilt.baseTexture, initial.baseTexture, "texture survives rebuild")
T.equal(rebuilt.decal, initial.decal, "decal survives rebuild")
T.equal(creations, 1, "same logical backpack never rerolls native visual")
T.equal(bag().itemState.condition, 8, "new inventory condition retained")
T.truthy(bag().itemState.modData.kept, "visual restoration preserves nonvisual state")
T.equal(#Model.BuildDefinition(draft).startingItems, 0,
    "preview continuity does not promote generated backpack to authored inventory")

-- Body changes resolve another runtime record, keeping the same generation.
draft.isFemale = true
T.near(portrait().tint.r, initial.tint.r, .0001, "body rebuild preserves backpack tint")
T.equal(creations, 1, "body change does not reroll bag")

-- A deliberate replacement with its own captured visual must win.
explicitState = { visualFullType = bagType, visualTintR = .9,
    visualTintG = .8, visualTintB = .7, visualTextureChoice = 6 }
draft.appearance.outfit = { mode = "none" }
T.near(portrait().tint.r, .9, .0001, "new explicit color is not overwritten")
T.equal(portrait().textureChoice, 6, "new explicit texture wins")

explicitState = nil
bagType = "Base.Bag_Schoolbag"
draft.appearance.outfit = { mode = "random" }
T.near(portrait().tint.r, .2, .0001, "different backpack type gets its own visual")
bagKey = "replacement:bag"
draft.appearance.outfit = { mode = "none" }
T.near(portrait().tint.r, .3, .0001, "different logical backpack does not inherit tint")

-- Explicit generation changes are fresh looks, even if item type/key match.
draft.previewSeed = 43
Model.EnsureRuntimeRecord(draft, true)
T.near(portrait().tint.r, .4, .0001, "new generation may roll a new backpack color")

-- Reopening a fresh draft is independent of the previous preview.
draft.runtimeRecord = nil
T.near(portrait().tint.r, .5, .0001, "fresh preview has no stale visual cache")
