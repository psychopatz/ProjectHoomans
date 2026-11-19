local T = require "tests/support/test"
T.addPackagePaths()
PNC = { Equipment = { Internal = {
    NormalizeString = function(value) return value end,
} } }
require "PNC/Core/Equipment/PNC_Equipment_Slots/VisualNormalization"
local variants = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringItemVariants"
local applied
PNC.Equipment.Internal.applyItemVisualState = function(_, state) applied = state end

local function list(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local asset = {
    getBaseTextures = function() return list({ "mod/Plain" }) end,
    getTextureChoices = function() return list({ "mod/Striped", "mod/Checked" }) end,
    getAllowRandomTint = function() return true end,
}
local item = { getClothingItem = function() return asset end }
local spec = { type = "MyMod.CheckedShirt" }
local original = {
    fullType = spec.type, baseTexture = 0, textureChoice = 0, decal = "ModBadge",
    tint = { r = .2, g = .3, b = .4 },
}
PNC.Equipment.StoreVisualStateInItemState(spec, original)
local groups = variants.Describe(item, original)
T.equal(#groups, 2, "single base texture does not create a selector")
T.equal(groups[1].options[2].label, "Checked", "designs come from the loaded mod asset")
variants.Apply(item, spec, original, groups[1].field, groups[1].options[2].value)
variants.Apply(item, spec, original, groups[2].field, groups[2].options[3].value)
local saved = PNC.Equipment.VisualStateFromItemState(spec.itemState, spec.type)
T.equal(saved.textureChoice, 1, "chosen design is persisted")
T.equal(saved.decal, "ModBadge", "changing tint preserves the decal")
T.equal(saved.customColor, true, "the engine gets an explicit color")
T.equal(saved.color.r, applied.color.r, "preview and stored tint match")
T.equal(variants.Describe(item, saved)[2].selected, 3, "saved palette color reopens selected")
variants.Apply(item, spec, original, groups[2].field, false)
T.equal(applied.tint.r, original.tint.r, "original asset tint can be restored")
T.equal(applied.textureChoice, 1, "resetting tint preserves the new design")
T.equal(#variants.Describe({}, {}), 0, "ordinary items never show clothing options")

local draws = 0
asset.getDecalGroup = function() return "ModPrints" end
ItemVisual = { new = function()
    return {
        setDecal = function() end,
        getDecal = function(_, source)
            T.equal(source, asset, "native decal sampling uses the selected asset")
            draws = draws + 1
            return draws % 2 == 0 and "ModBadge" or "AnotherPrint"
        end,
    }
end }
local decals = variants.Decals(item, original)
T.equal(#decals, 2, "native decal draws are deduplicated")
local prints = variants.Describe(item, original, decals)[2]
T.equal(prints.field, "decal", "mod decal group enables a print selector")
variants.Apply(item, spec, original, prints.field, prints.options[2].value)
T.equal(applied.decal, "AnotherPrint", "selected print reaches native visual")

asset.getAllowRandomHue = function() return true end
local hue = variants.Describe(item, original, decals)[3]
T.equal(hue.field, "hue", "assets that use hue variation expose it")
variants.Apply(item, spec, original, hue.field, hue.options[2].value)
saved = PNC.Equipment.VisualStateFromItemState(spec.itemState, spec.type)
T.equal(saved.hue, applied.hue, "hue shift round-trips in stored native visual state")
