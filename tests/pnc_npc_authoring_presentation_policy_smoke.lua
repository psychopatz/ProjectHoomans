local T = require 'tests/support/test'
local F = require('tests/support/pnc_authoring_ui')()
local Fields = PNC.NPCAuthoringFields
local companion = F.Class:new(0, 0, 1060, 620, { mode = 'companion', parent = { presentationMode = 'debug' }, uiScale = 1 })
companion:initialise(); companion:instantiate()
T.falsy(Fields.CanRandomize(companion), 'host capability uses the actual editor mode')
T.falsy(companion.randomizeButton, 'companion toolbar has no random action')
local called = 0
companion.presentationAdapter = { Randomize = function() called = called + 1 end }
T.falsy(companion:invokeWorkflow('randomize'), 'hidden companion workflow route is rejected')
T.equal(called, 0, 'rejected workflow cannot touch canonical generation')
local combo = F.Base:new(0, 0, 1, 1)
Fields.Options(companion, combo, { { id = 'random', label = 'Random' }, { id = '__random', label = 'Random' }, { id = '', label = 'None' }, { id = 'Long', label = 'Long' } }, nil)
for _, option in ipairs(combo.options) do T.falsy(option.text == 'Random', 'no Random option is visible in companion mode') end
T.equal(combo.options[combo.selected].data, '__current', 'generated appearance is a display-only current selection')
Fields.Select(companion, combo, 'Long')
T.equal(combo.options[combo.selected].data, 'Long', 'concrete styles bind by semantic value')
local debug = { presentationMode = 'debug' }
Fields.Options(debug, combo, { { id = 'random', label = 'Random' } }, 'random')
T.equal(combo.options[combo.selected].data, 'random', 'debug retains random choices')
-- Production appearance builders obey the same capability, not option indexes.
local A = ISPNCUniqueNPCAppearanceWindow
A.Internal = { tr = function(_, fallback) return fallback end,
    voiceOptions = function() return { { id = 1, label = 'Chris' } } end,
    addOptions = function(control, values) Fields.Options(debug, control, values, values[1] and values[1].id) end,
    selectData = function(control, id) Fields.Select(debug, control, id) end,
    comboData = function(control) return control.options[control.selected].data end }
T.load('ProjectHoomans', 'client', 'PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Controls_Options.lua')
getAllOutfits = function() return { size = function() return 1 end, get = function() return 'Bandit' end } end
local appearance = setmetatable({ parentEditor = companion, draft = { isFemale = false }, outfitCombo = F.Base:new(0, 0, 1, 1), voiceCombo = F.Base:new(0, 0, 1, 1), voiceSampleCombo = F.Base:new(0, 0, 1, 1) }, { __index = A })
appearance:buildOutfitOptions(); appearance:buildVoiceOptions()
for _, control in ipairs({ appearance.outfitCombo, appearance.voiceCombo }) do
    for _, option in ipairs(control.options) do T.falsy(option.text == 'Random', 'production appearance catalogs omit companion random choices') end
end
local changed = 0
A.Internal.Appearance = { Normalize = function(value) return value end }
T.load('ProjectHoomans', 'client', 'PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow_Editing.lua')
function appearance:markChanged() changed = changed + 1 end
appearance.draft.identity = { survivor = { hairModel = 'Long' } }
appearance:onHairChanged({ selected = 1, options = { { data = '__random' } } })
T.equal(appearance.draft.identity.survivor.hairModel, 'Long', 'stale random style callback cannot clear companion hair')
T.equal(changed, 0, 'rejected random style cannot commit')
appearance:onAppearanceToggle(1, true, "chestHair")
T.equal(appearance.draft.identity.survivor.chestHair, true, 'checked appearance toggle authors true')
appearance:onAppearanceToggle(1, false, "chestHair")
T.equal(appearance.draft.identity.survivor.chestHair, false, 'unchecked appearance toggle authors false')
appearance.draft.isFemale = true
appearance:onAppearanceToggle(1, true, "chestHair")
T.equal(changed, 2, 'disabled female chest hair cannot be authored by a stale click')
appearance:onAppearanceToggle(1, true, "hairStubble")
T.equal(appearance.draft.identity.survivor.hairStubble, true, 'female scalp stubble stays editable')
T.finish('pnc_npc_authoring_presentation_policy_smoke')
