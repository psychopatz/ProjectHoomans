local T = require 'tests/support/test'
local F = require('tests/support/pnc_authoring_ui')()
local function copy(v) if type(v) ~= 'table' then return v end; local out = {}; for k, child in pairs(v) do out[k] = copy(child) end; return out end
PNC.NPCAuthoring = { Registry = { Copy = copy } }
T.load('ProjectHoomans', 'shared', 'PNC/Core/Identity/PNC_Identity_Appearance.lua')
T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringLoadout.lua')
T.load('ProjectHoomans', 'client', 'PNC/UI/NPCAuthoring/PNC_NPCAuthoringCatalog.lua')
local A, Slots, Catalog = PNC.Identity.Appearance, PNC.NPCAuthoringSlots, PNC.NPCAuthoringCatalog
A.AreExclusive = function(a, b) return a == 'Pants' and b == 'Shorts' or a == 'Shorts' and b == 'Pants' end -- native metadata boundary
PNC.Equipment = { NormalizeLoadoutSpec = function(value) return value end }
PNC.UniqueNPCAppearanceUI.Internal.locations = function() return { 'Pants', 'Shorts', 'UnderwearBra', 'ForearmLeft', 'Neck', 'mod:UtilitySocket' } end
Catalog.Clothing = function() return { { id = 'Base.Item' } } end
Catalog.Find = function(id) return { label = id, script = { getNormalTexture = function() end } } end
Catalog.Items = function() return { { id = 'Base.Money', label = 'Money', search = 'base.money money' } } end
Catalog.Create = function(id) return { fullType = id } end
PNC.Inventory = { CaptureNativeItem = function(native) return { type = native.fullType } end }
T.equal(Slots.Group('base:ForearmLeft').id, 'hands', 'forearm is not mistaken for an ear')
T.equal(Slots.Group('base:UnderwearBra').id, 'torso', 'bra is not mistaken for an ear')
T.equal(Slots.Group('base:UnderwearLongJohns').id, 'legs', 'leg underwear is grouped with legs')
T.equal(Slots.Group('base:FullSuitHead').id, 'head', 'specific head component wins over generic suit')
T.equal(Slots.Group('mod:UtilitySocket').id, 'other', 'unknown mod locations remain accessible')
local draft = { identity = { survivor = {} }, appearance = { slots = { Pants = { mode = 'item', type = 'Base.Pants' } } }, startingItems = {
    { key = 'money', type = 'Base.Money', stack = 5, preferredContainer = 'bag' },
    { key = 'food', type = 'Base.Food', stack = 2 },
} }
local function has(rows, id) for _, row in ipairs(rows) do if row.id == id then return true end end; return false end
T.falsy(has(Slots.Build(draft), 'Shorts'), 'an empty exclusive slot is hidden while pants are equipped')
T.truthy(PNC.NPCAuthoringLoadout.SetSlot(draft, { kind = 'worn', id = 'Pants' }))
T.truthy(has(Slots.Build(draft), 'Shorts'), 'clearing the blocking item restores the alternative immediately')
local e = F.Class:new(0, 0, 1060, 700, { mode = 'debug', uiScale = 1 })
e:initialise(); e:instantiate(); e.draft = draft
F.Model.BuildBlueprint = function() return {} end
function e:pullForm() return true end
function e:refreshPreview() self:refreshLoadoutPage() end
e:refreshLoadoutPage()
T.equal(#e.carriedList.items, 2, 'carried inventory has one list row per authored item')
e.loadoutPart = 'carry'; e:onResponsiveLayout()
T.truthy(e.carriedPanel.visible, 'carried inventory is a distinct view')
T.falsy(e.slotContent.visible, 'carried inventory does not show body slot tiles')
T.falsy(e.loadoutModeRow.entry.visible, 'equipment-generation choices do not crowd carried inventory')
e.carriedList.selected = 1; e.carriedActions[2].onclick(e)
T.equal(e.itemExplorer.mode, 'carry', 'editing an existing carried item uses inventory controls')
T.equal(e.itemExplorer.quantity:getText(), '5', 'editing starts with existing quantity')
T.equal(e.itemExplorer.destination.options[e.itemExplorer.destination.selected].data, 'bag', 'editing retains the designated destination')
T.truthy(e.itemExplorer.onChoose({ id = 'Base.Money' }, 7, 'root'))
T.equal(e.draft.startingItems[2].stack, 7, 'confirmed inventory edit uses the requested quantity')
T.equal(e.draft.startingItems[1].type, 'Base.Food', 'editing money leaves food intact')
T.equal(e.draft.startingItems[2].preferredContainer, nil, 'pockets destination replaces the old bag destination')
T.finish('pnc_npc_authoring_body_parts_smoke')
