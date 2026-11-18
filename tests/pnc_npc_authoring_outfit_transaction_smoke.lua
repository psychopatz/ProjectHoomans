local T = require 'tests/support/test'
local F = require('tests/support/pnc_authoring_ui')()
local function copy(v)
    if type(v) ~= 'table' then return v end
    local out = {}; for k, child in pairs(v) do out[k] = copy(child) end; return out
end
PNC.NPCAuthoring = { Registry = { Copy = copy } }
T.load('ProjectHoomans', 'shared', 'PNC/Core/Identity/PNC_Identity_Appearance.lua')
T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringLoadout.lua')
T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringCatalog.lua')
T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor_Loadout.lua')
local e = F.Class:new(0, 0, 1060, 620, { mode = 'companion', uiScale = 1 })
e:initialise(); e:instantiate()
e.draft = { identity = { survivor = {} }, appearance = { outfit = { mode = 'none' }, slots = {} }, startingItems = {
    { type = 'Base.OldShirt', wornSlot = 'Torso' }, { type = 'Base.Axe', equipSlot = 'primary' },
    { type = 'Base.Bag', wornSlot = 'Back', maxWeight = 20 } } }
function e:pullForm() return true end
local applied = 0
function e.appearanceTab:markChanged() applied = applied + 1 end
F.Model.BuildPreviewDraft = copy
F.Model.EnsureRuntimeRecord = function(preview) preview.runtimeRecord = {}; return preview.runtimeRecord end
F.Model.BuildPortraitSpec = function(preview) return { key = preview.appearance.outfit.id or 'none', appearance = copy(preview.appearance) } end
F.Model.BuildBlueprint = function() return {} end
local captures = 0
PNC.NPCAuthoringLoadout.CaptureOutfit = function()
    captures = captures + 1
    return { Torso = { mode = 'item', type = 'Base.NewShirt', itemState = { visualTextureChoice = captures } } }
end
local options = { { data = '__current', text = 'Current value' }, { data = 'random', text = 'Random' },
    { data = 'named:Bandit', text = 'Bandit' }, { data = 'none', text = 'None' } }
e.appearanceTab.outfitCombo.options = options
local before = e.draft
e:browseOutfits()
local browser = e.itemExplorer
T.equal(#browser.visibleRows, 2, 'companion outfit browser omits random/current pseudo entries')
browser.tiles[1].onclick(browser, browser.tiles[1])
T.equal(captures, 1, 'only the focused outfit is materialized')
browser.tiles[1].onclick(browser, browser.tiles[1])
T.equal(captures, 1, 'reselecting an outfit reuses its exact preview')
T.equal(e.draft, before, 'focused preview leaves accepted draft untouched')
T.equal(e.draft.startingItems[1].type, 'Base.OldShirt', 'preview does not strip accepted clothing')
browser:Hide()
T.equal(applied, 0, 'Cancel never applies clothing')
e:browseOutfits(); browser.tiles[1].onclick(browser, browser.tiles[1])
local previewState = captures
browser.confirm.onclick(browser)
T.equal(applied, 1, 'Apply commits exactly once')
T.equal(e.draft.appearance.slots.Torso.itemState.visualTextureChoice, previewState, 'Apply uses the exact reviewed clothing state')
T.equal(#e.draft.startingItems, 2, 'complete outfit replaces old authored clothing')
T.equal(e.draft.startingItems[1].type, 'Base.Axe', 'outfit application preserves held equipment')
T.equal(e.draft.startingItems[2].type, 'Base.Bag', 'outfit application preserves bag capacity/ownership')
e:browseOutfits(); browser.tiles[2].onclick(browser, browser.tiles[2]); browser.confirm.onclick(browser)
T.equal(e.draft.appearance.outfit.mode, 'none', 'explicit None remains available')
T.falsy(next(e.draft.appearance.slots), 'None cannot resurrect the previous outfit')
T.finish('pnc_npc_authoring_outfit_transaction_smoke')
