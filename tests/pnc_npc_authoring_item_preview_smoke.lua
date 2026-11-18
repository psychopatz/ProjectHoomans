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
catalog.Query = function(options)
    return { { id = 'Base.Necklace', label = 'Necklace', script = script } }, 1
end
catalog.Filters = function() return {} end
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
e:openSlot(slot)
local browser = e.itemExplorer
browser.tiles[1].onclick(browser, browser.tiles[1])
T.equal(browser.preview:getViewRegion(), 'neck', 'item viewer frames the region being edited')
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
T.finish('pnc_npc_authoring_item_preview_smoke')
