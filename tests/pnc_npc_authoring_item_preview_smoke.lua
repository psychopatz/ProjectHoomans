local F = require('tests/support/pnc_authoring_ui')()
local T = require 'tests/support/test'
local function copy(v) if type(v) ~= 'table' then return v end; local out = {}; for k, child in pairs(v) do out[k] = copy(child) end; return out end
PNC.NPCAuthoring = { Registry = { Copy = copy } }
T.load('ProjectHoomans', 'shared', 'PNC/Core/Identity/PNC_Identity_Appearance.lua')
T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringLoadout.lua')
T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringCatalog.lua')
local catalog, captures = PNC.NPCAuthoringCatalog, 0
local script = { getNormalTexture = function() return nil end }
catalog.Find = function(id) return { id = id, label = id, script = script } end
catalog.Clothing = function() return { { id = 'Base.Necklace' } } end
catalog.Create = function(id)
    captures = captures + 1
    return { fullType = id, tint = captures / 10 }
end
catalog.Items = function()
    return { { id = 'Base.Necklace', label = 'Necklace', script = script, search = 'necklace' } }
end
PNC.Equipment = { NormalizeLoadoutSpec = function(v) return v end }
PNC.UniqueNPCAppearanceUI.Internal.locations = function() return { 'Neck' } end
PNC.Inventory = { CaptureNativeItem = function(item) return { type = item.fullType, itemState = { visualTintR = item.tint } } end }
F.Model.BuildBlueprint = function() return {} end
F.Model.BuildPreviewDraft = copy
F.Model.EnsureRuntimeRecord = function(draft) draft.runtimeRecord = {}; return draft.runtimeRecord end
F.Model.BuildPortraitSpec = function(draft) return { key = tostring(draft.appearance.slots.Neck.itemState.visualTintR), appearance = copy(draft.appearance) } end
local e = F.Class:new(0, 0, 1060, 700, { mode = 'companion', uiScale = 1 })
e:initialise(); e:instantiate()
e.draft = { displayName = 'Sam', identity = { survivor = {} }, appearance = { slots = {} }, startingItems = {} }
function e:pullForm() return true end
function e:refreshPreview() self:refreshLoadoutPage() end
e.loadoutPart, e.loadoutViewRegion = 'neck', 'neck'
local slot = { kind = 'worn', id = 'Neck', group = 'neck', label = 'Neck' }
local original = e.draft
local now = 1000
getTimeInMillis = function() return now end
e:openSlot(slot)
local browser = e.itemExplorer
browser.tiles[1].onclick(browser, browser.tiles[1])
T.equal(browser.preview:getViewRegion(), 'neck', 'item viewer frames the region being edited')
T.truthy(browser.preview.cameraTransition, 'the picker eases from body framing to the selected slot')
now = now + 250
local previousZoom = browser.preview.zoom
browser.previewZoom[2].onclick(browser.preview)
T.equal(browser.preview.zoom, previousZoom + 1, 'picker zoom uses the shared camera')
T.truthy(browser.preview.cameraTransition, 'picker zoom is animated')
T.equal(e.draft, original, 'item inspection never mutates the accepted draft')
local tint = browser.preview.spec.appearance.slots.Neck.itemState.visualTintR
browser.tiles[1].onclick(browser, browser.tiles[1])
T.equal(captures, 1, 'reselecting an item does not roll another native tint')
browser.tiles[1]:onMouseDoubleClick()
T.equal(e.draft.appearance.slots.Neck.itemState.visualTintR, tint, 'double-click equips the exact appearance shown in the item viewer')
T.equal(captures, 1, 'confirmation reuses the captured native choice')
T.falsy(browser.visible, 'confirmed item preview is dismissed')
local accepted = e.draft
e:openSlot(slot); browser.tiles[1].onclick(browser, browser.tiles[1]); browser:Hide()
T.equal(e.draft, accepted, 'Cancel preserves the previously accepted loadout')
local held = { kind = 'held', id = 'secondary', group = 'held', label = 'Off hand' }
local candidateSpec = { key = 'weapon-look', equipment = { secondaryFullType = 'Base.Hammer' } }
local chosen
function e:buildLoadoutCandidate(_, _, _, _, selection) chosen = selection; return {} end
F.Model.BuildPortraitSpec = function() return candidateSpec end
local baseline = { identity = { survivor = { hairModel = 'Pompadour' } },
    inventory = { items = { shirt = { type = 'Base.Shirt' } } } }
e.previewDraft = { runtimeRecord = baseline }
F.Model.EnsureRuntimeRecord = function(draft, force)
    T.equal(force, nil, 'gear preview uses the retained look path')
    T.equal(draft.runtimeRecord.identity.survivor.hairModel, 'Pompadour', 'face is kept for a try-on')
    draft.runtimeRecord.inventory.items.shirt.type = 'Base.OtherShirt'
    return draft.runtimeRecord
end
local inspect = e:loadoutPickerCallbacks(held, { ['Base.Hammer'] = true })
local portrait = inspect({ id = 'Base.Hammer', label = 'Hammer' })
T.equal(portrait.previewHandItems.secondary, chosen.native, 'selected weapon goes into the requested preview hand')
T.equal(portrait.previewHandItems.primary, nil, 'off-hand selection does not replace the primary hand')
T.equal(e.draft, accepted, 'in-hand rendering never mutates the accepted loadout')
T.equal(baseline.inventory.items.shirt.type, 'Base.Shirt', 'try-on cannot change the baseline wardrobe')

local selectedDesign, equippedDesign
local variantOptions = {
    items = { { id = 'Base.Necklace', label = 'Necklace' } },
    initialID = 'Base.Necklace',
    variants = function()
        return { { field = 'textureChoice', key = 'UI_PNC_Authoring_Design', label = 'Design',
            selected = selectedDesign and selectedDesign + 1 or 1, options = {
                { value = 0, label = 'Plain' }, { value = 1, label = 'Striped' },
            } } }
    end,
    preview = function() return { key = 'variant-look', design = selectedDesign } end,
    changeVariant = function(_, _, value) selectedDesign = value end,
    onChoose = function() equippedDesign = selectedDesign; return true end,
    beginVariantEdit = function()
        local previous = selectedDesign
        return function(accepted) if not accepted then selectedDesign = previous end end
    end,
}
browser:Show(variantOptions)
T.truthy(browser.variantButton:getIsVisible(), 'Change is visible for the selected item')
browser.variantButton.onclick(browser)
local dialog = browser.variantDialog
T.truthy(dialog.inUIManager, 'the completed card is mounted as a top-level window')
T.truthy(dialog.alwaysOnTop, 'card opens in front of its browser')
T.equal(dialog.parent, nil, 'no foreground overlay is attached to the browser')
local variantList = dialog.list
T.equal(#variantList.items, 3, 'group and variants are visible without opening a dropdown')
variantList.onmousedown(browser, variantList.items[3].item)
T.equal(dialog.portrait.spec.design, 1, 'design updates the dialog portrait live')
T.equal(browser.preview.spec.design, nil, 'picker portrait keeps its previous design until Apply')
T.falsy(browser:confirmSelection(), 'cannot equip while the design is staged')
dialog.cancel.onclick(browser)
T.equal(selectedDesign, nil, 'Cancel discards the staged variant')
T.falsy(dialog.inUIManager, 'Cancel removes the window from input dispatch')
browser.variantButton.onclick(browser)
dialog = browser.variantDialog
variantList = dialog.list
variantList.onmousedown(browser, variantList.items[3].item)
dialog.apply.onclick(browser)
T.equal(selectedDesign, 1, 'Apply keeps the exact asset index')
T.equal(equippedDesign, 1, 'Apply equips the staged design directly')
T.falsy(browser:getIsVisible(), 'successful Apply returns to the editor')
T.equal(browser.variantDialog, nil, 'applying closes the variant window')
browser:Show(variantOptions)
browser.variantButton.onclick(browser)
dialog = browser.variantDialog
browser:Hide()
T.falsy(dialog.inUIManager, 'closing the browser removes its variant window')

browser:Show({
    items = { { id = 'Base.Necklace', label = 'Necklace' } },
    initialID = 'Base.Necklace',
    variants = function() return {} end,
    changeVariant = function() error('fixed item cannot be changed') end,
})
T.falsy(browser.variantButton:getIsVisible(), 'fixed-design items hide Change')
browser.variantButton.onclick(browser)
T.equal(browser.variantDialog, nil, 'unsupported items cannot mount a dialog')

local currentLook = { key = 'accepted-look' }
browser:Show({
    items = { { id = 'Base.Necklace', label = 'Necklace' } },
    initialID = 'Base.Necklace',
    baselinePreview = currentLook,
    preview = function() return nil, nil, 1, 'Clear the other hand' end,
})
T.equal(browser.preview.spec, currentLook, 'incompatible try-on keeps the current NPC visible')
T.equal(browser.hintText, 'Clear the other hand', 'picker shows the specific fit error')
T.falsy(browser:confirmSelection(), 'fallback portrait does not allow an incompatible item')
browser.selectedID = nil
browser:refreshDetails()
T.equal(browser.preview.spec, currentLook, 'no selected search result keeps the current NPC visible')
T.equal(browser.preview:getViewRegion(), 'body', 'unselected equipment uses the full-body framing')
T.equal(browser.preview.zoom, -3, 'unselected preview uses the neutral full-body zoom')
local capturedState
PNC.Equipment.VisualStateFromItemState = function(state) return { tint = { r = state.visualTintR } } end
PNC.Equipment.StoreVisualStateInItemState = function(spec, state) spec.itemState.visualTintR = state.tint.r end
PNC.Equipment.Internal = { applyItemVisualState = function(_, state) capturedState = state end }
local _, _, _, _, stageVariant, beginVariant = e:loadoutPickerCallbacks({ kind = 'carry', id = 'new' })
local item = { id = 'Base.Necklace' }
local restore = beginVariant(item)
local initialTint = captures / 10
stageVariant(item, 'color', { r = .9, g = .8, b = .7 })
T.equal(capturedState.tint.r, .9, 'stage applies visual state to the native try-on item')
restore(false)
T.equal(capturedState.tint.r, initialTint, 'cancel restores the exact native visual state')
F.Model.BuildPortraitSpec = function()
    return { key = 'cached-look', equipment = {
        worn = { Neck = 'Base.Necklace' }, wornVisuals = { Neck = { tint = { r = .2 } } },
    } }
end
local inspectVariant, _, _, _, changeWornVariant, beginWornVariant =
    e:loadoutPickerCallbacks({ kind = 'worn', id = 'base:Neck' })
local restoreWorn = beginWornVariant(item)
changeWornVariant(item, 'color', { r = .9, g = .8, b = .7 })
local latestPortrait = inspectVariant(item)
T.equal(latestPortrait.equipment.wornVisuals.Neck.tint.r, .9,
    'portrait uses the staged visual over the cached wardrobe')
T.equal(latestPortrait.equipment.worn['base:Neck'], nil, 'the canonical slot is not duplicated')
restoreWorn(false)
local cosmetics = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringCosmetics"
local dressed = { key = 'face-with-gear', appearance = { outfit = 'Test Outfit' }, equipment = { worn = {
    ['base:Eyes'] = 'Base.Glasses', ['base:MaskFull'] = 'Base.Mask',
    ['base:MakeUp_Eyes'] = 'Base.MakeUp_Crow', ['base:MakeUp_Lips'] = 'Base.MakeUp_LipsRed',
} } }
browser:Show({
    items = { { id = 'Base.Necklace', label = 'Necklace' } },
    initialID = 'Base.Necklace',
    faceDetail = true,
    projectPreview = cosmetics.FacePreview,
    preview = function() return dressed end,
})
T.equal(browser.preview:getViewRegion(), 'head', 'makeup inspection focuses on the face')
local face = browser.preview.spec.equipment.worn
T.equal(face['base:Eyes'], nil, 'glasses do not cover makeup in the inspection portrait')
T.equal(face['base:MaskFull'], nil, 'mask does not cover makeup in the inspection portrait')
T.equal(face['base:MakeUp_Eyes'], 'Base.MakeUp_Crow', 'selected eye makeup remains on the portrait')
T.equal(face['base:MakeUp_Lips'], 'Base.MakeUp_LipsRed', 'other makeup layers stay on the portrait')
T.equal(dressed.equipment.worn['base:MaskFull'], 'Base.Mask', 'inspection never removes equipment from the draft')
local loaded
browser:Show({
    mode = 'preset',
    items = { { id = 'Base.Necklace', label = 'Preset' } },
    initialID = 'Base.Necklace',
    previewRequired = false,
    preview = function() return nil, nil, 1, 'portrait_unavailable' end,
    onChoose = function(entry) loaded = entry.id; return true end,
})
T.truthy(browser:confirmSelection(), 'a failed preset portrait never prevents loading')
T.equal(loaded, 'Base.Necklace', 'Load reaches the preset action even without a portrait')
T.finish('pnc_npc_authoring_item_preview_smoke')
