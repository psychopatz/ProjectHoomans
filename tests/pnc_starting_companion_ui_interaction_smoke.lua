local T = require "tests/support/test"

T.addPackagePaths()

local function button(definition)
    local value = {
        internal = definition.id,
        title = definition.title,
        visible = true,
        enabled = true,
    }
    function value:setVisible(nextVisible) self.visible = nextVisible end
    function value:setEnable(enabled) self.enabled = enabled end
    function value:setEnabled(enabled) self.enabled = enabled end
    function value:setTitle(nextTitle) self.title = nextTitle end
    function value:getTitle() return self.title end
    return value
end

local function label(_, x, y, height, name)
    local value = { x = x, y = y, height = height, name = name, visible = true }
    function value:setVisible(nextVisible) self.visible = nextVisible end
    function value:setName(nextName) self.name = nextName end
    function value:initialise() end
    return value
end

local function combo()
    local value = { options = {}, selected = 0, visible = true }
    function value:initialise() end
    function value:instantiate() end
    function value:setVisible(nextVisible) self.visible = nextVisible end
    function value:setEnabled(enabled) self.enabled = enabled end
    function value:setEnable(enabled) self.enabled = enabled end
    function value:clear()
        self.options = {}
        self.selected = 0
    end
    function value:addOptionWithData(text, data)
        self.options[#self.options + 1] = { text = text, label = text, data = data }
    end
    function value:selectData(data)
        self.selected = 0
        for index, option in ipairs(self.options) do
            if option.data == data then
                self.selected = index
                return
            end
        end
    end
    function value:invokeChange()
        return self.onChange(self.target, self)
    end
    return value
end

local function keyValueList()
    local value = { items = {}, currentTraitID = nil }
    function value:clear() self.items = {} end
    function value:addItem(labelText, item)
        self.items[#self.items + 1] = { label = labelText, item = item }
    end
    return value
end

local UI = {
    Layout = {},
    CreateButton = function(_, definition) return button(definition) end,
    CreateKeyValueList = function() return keyValueList() end,
    AddKeyValue = function(list, labelText, valueText)
        list:addItem(labelText, { label = labelText, value = valueText })
    end,
    SetLabelText = function(target, value) target:setName(value) end,
    NewWindow = function() return nil end,
}
function UI.Layout.Pixels(value) return value end
function UI.Layout.Flow(controls, rect)
    for index, control in ipairs(controls) do UI.Layout.SetBounds(control, rect.x + (index - 1) * 110, rect.y, 100, 32) end
    return { bottom = rect.y + 32 }
end
function UI.Layout.SetBounds(control, x, y, width, height)
    if not control then return end
    control.x, control.y = x, y
    control.width, control.height = width, height
end

PsychopatzCore = { UI = UI }
UIFont = { Small = 1 }

local BaseWindow = {}
BaseWindow.__index = BaseWindow
function BaseWindow:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end
function BaseWindow:new(x, y, width, height, options)
    local object = {
        x = x, y = y, width = width, height = height,
        options = options or {}, children = {}, uiScale = 1,
    }
    return setmetatable(object, self)
end
function BaseWindow:initialise() end
function BaseWindow:createChildren() end
function BaseWindow:addChild(child) self.children[#self.children + 1] = child end
function BaseWindow:setVisible(value) self.visible = value end
function BaseWindow:removeFromUIManager() self.removed = true end
function BaseWindow:bringToTop() self.broughtToTop = true end
function BaseWindow:getContentRect(options)
    options = options or {}
    local top = options.top or 30
    return { x = 8, y = top, width = self.width - 16, height = self.height - top - (options.bottom or 8) }
end
function BaseWindow:close() self:setVisible(false) end
PsychopatzFixedWindow = BaseWindow:derive("PsychopatzFixedWindow")

ISComboBox = { new = function() return combo() end }
ISLabel = { new = label }

local brother = "PNC_HasBrother"
local sister = "PNC_HasSister"
local selectedPreset = "sister-template.txt"
local slots = {
    {
        traitID = brother,
        active = true,
        spec = { relationshipKind = "brother", uiName = "Brother" },
    },
    {
        traitID = sister,
        active = true,
        spec = { relationshipKind = "sister", uiName = "Sister" },
    },
}

local session = {}
function session:GetActiveSlots() return slots end
function session:GetSlot(traitID, includeInactive)
    for _, slot in ipairs(slots) do
        if slot.traitID == traitID and (includeInactive or slot.active) then
            return slot
        end
    end
    return nil
end
function session:FinalSummary()
    return {
        { traitID = brother, relationshipKind = "brother", displayName = "Jorge patz" },
        { traitID = sister, relationshipKind = "sister", displayName = "Jane patz" },
    }
end

local function draftFor(traitID, seed)
    local female = traitID == sister
    return {
        identity = {
            nickname = nil,
            survivor = { forename = female and "Jane" or "Jorge", surname = "patz" },
        },
        isFemale = female,
        previewSeed = seed,
    }
end

local Adapter = {}
function Adapter.New(owner, traitID)
    local value = { session = owner, traitID = traitID, seed = 10 }
    return setmetatable(value, { __index = Adapter })
end
function Adapter:BuildDraft() return draftFor(self.traitID, self.seed) end
function Adapter:PreviewIdentity()
    return self.traitID .. ":blueprint:stable:seed:" .. self.seed
end
function Adapter:PreviewGenerationIdentity() return self:PreviewIdentity() end
function Adapter:Randomize() self.seed = self.seed + 1 return true end
function Adapter:Reset() self.seed = 10 return true end
function Adapter:RevertToPreset() self.seed = 12 return true end

local editorClass = {}
function editorClass:new()
    local explorer = { visible = false }
    function explorer:getIsVisible() return self.visible end
    function explorer:Show(options) self.visible = true; self.options = options end
    function explorer:Hide() self.visible = false; if self.onDismiss then self.onDismiss() end end
    return setmetatable({ itemExplorer = explorer }, { __index = self })
end
function editorClass:initialise() end
function editorClass:instantiate() end
function editorClass:setAdapter(adapter)
    self.adapter = adapter
    if not adapter then
        self.draft = nil
        self.form = nil
        self.portraitTarget = nil
        self.statusText = "No companion selected"
        return
    end
    self.draft = adapter:BuildDraft()
    self.form = {
        gender = self.draft.isFemale and "Female" or "Male",
        surname = self.draft.identity.survivor.surname,
        firstName = self.draft.identity.survivor.forename,
    }
    self.previewIdentity = adapter:PreviewIdentity()
    self.portraitTarget = { traitID = adapter.traitID }
    self.statusText = "Companion ready"
end
function editorClass:invokeWorkflow(action)
    local method = action == "randomize" and "Randomize"
        or action == "reset" and "Reset"
        or action == "revert" and "RevertToPreset" or nil
    if not method then return false end
    local ok = self.adapter[method](self.adapter)
    self:setAdapter(self.adapter)
    return ok
end
function editorClass:pullForm() self.flushed = true end
function editorClass:requestResponsiveLayout() end
function editorClass:setRoster(rows, selected, callback)
    self.rosterRows, self.rosterSelection, self.onSelectRoster = rows, selected, callback
end

local appliedPreset, appliedOptions
local Presets = {
    TemplateFromSession = function(_, traitID, label)
        return { kind = "template", companionTraitID = traitID, label = label }, nil
    end,
    FromSession = function() return { kind = "whole", label = "set" }, nil end,
    ApplyToSession = function(_, payload, options)
        appliedPreset, appliedOptions = payload, options
        return { applied = { options.targetTraitID or brother } }, nil
    end,
}
local Store, presetReads = {}, 0
function Store.List()
    presetReads = presetReads + 1
    return { { fileName = selectedPreset, label = "Sister template" } }
end
function Store.Load(fileName)
    return { kind = "template", companionTraitID = sister, fileName = fileName }, nil
end
function Store.Save() return true, selectedPreset end

PNC = {
    Translation = { GetKey = function(key, fallback) return fallback or key end },
    StartingCompanionTraits = {
        GetDefinition = function(traitID)
            return traitID == brother and slots[1].spec
                or traitID == sister and slots[2].spec or nil
        end,
    },
    StartingCompanionPresets = Presets,
    StartingCompanionPresetStore = Store,
    StartingCompanionAuthoringAdapter = Adapter,
}

package.preload["PsychopatzCore/UI/PsychopatzUI"] = function() return UI end
package.preload["PsychopatzCore/UI/PsychopatzFixedWindow"] = function()
    _G.PsychopatzFixedWindow = PsychopatzFixedWindow
    return PsychopatzFixedWindow
end
package.preload["ISUI/ISComboBox"] = function() return ISComboBox end
package.preload["ISUI/ISLabel"] = function() return ISLabel end
package.preload["PNC/Core/Traits/PNC_StartingCompanionTraits"] = function()
    return PNC.StartingCompanionTraits
end
package.preload["PNC/CharacterCreation/PNC_StartingCompanionPresets"] = function()
    return Presets
end
package.preload["PNC/CharacterCreation/PNC_StartingCompanionPresetStore"] = function()
    return Store
end
package.preload["PNC/CharacterCreation/PNC_StartingCompanionAuthoringAdapter"] = function()
    return Adapter
end
package.preload["PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor"] = function()
    ISPNCNPCAuthoringEditor = editorClass
    return { ISPNCNPCAuthoringEditor = editorClass }
end

PNC.NPCAuthoringFields = { NativeMetrics = function() end, EnableButton = function(control, enabled) control:setEnable(enabled) end }

local UIState = T.load("ProjectHoomans", "client",
    "PNC/UI/StartingCompanions/PNC_StartingCompanionComposerWindow.lua")
local window = ISPNCStartingCompanionComposerWindow:new(0, 0, 1060, 800,
    { session = session })
window:initialise()
window:createChildren()
window:onResponsiveLayout()
T.falsy(window.revertButton, "there is one reset action")
T.truthy(window.doneButton.y > window.loadButton.y, "Done sits in the footer")
T.equal((window.resetButton.x + window.doneButton.x + window.doneButton.width) / 2,
    window.width / 2, "Reset and Done are centered together")
window:refresh()
T.equal(presetReads, 0, "opening does not read saved preset files")
T.truthy(window.loadButton.y >= 30, "toolbar reserves the native title bar")
T.truthy(window.editor.y >= window.loadButton.y + 32, "editor starts below the toolbar")
T.falsy(window.saveSetButton, 'roster saving is absent from the editing toolbar')

T.equal(window.selectedTraitID, brother,
    "native callback harness starts on the first active companion")
T.equal(window.adapter.traitID, brother, "initial adapter matches selector")

window.editor.onSelectRoster(sister)
T.equal(window.selectedTraitID, sister,
    "vanilla onChange(target, combo) updates selected companion")
T.equal(window.adapter.traitID, sister, "adapter follows selected companion")
T.equal(window.editor.form.gender, "Female", "sister form gender is refreshed")
T.equal(window.editor.form.surname, "patz", "sister inherited surname is refreshed")
T.equal(window.editor.form.firstName, "Jane", "sister form identity is refreshed")
T.equal(window.currentSelection.traitID, sister,
    "summary current selection follows the slot transaction")
T.equal(window.editor.portraitTarget.traitID, sister,
    "portrait target follows the slot transaction")
T.falsy(window.statusText == "No starting companion trait selected",
    "valid selection does not leave the no-selection status")

local oldSeed = window.adapter.seed
local oldIdentity = window.editor.previewIdentity
window:onAction({ internal = "randomize" })
T.equal(window.selectedTraitID, sister,
    "randomize retains the selected companion")
T.equal(window.adapter.seed, oldSeed,
    "companion host rejects randomization")
T.equal(window.editor.previewIdentity, oldIdentity,
    "rejected randomization preserves preview identity")
T.equal(window.editor.portraitTarget.traitID, sister,
    "randomize keeps the portrait on the selected companion")

window:SelectCompanion(brother)
window:refreshPresets()
window.presetCombo:selectData(selectedPreset)
window.presetCombo:invokeChange()
T.equal(window.selectedPresetFile, selectedPreset,
    "vanilla preset callback stores the visible preset")
window:onAction({ internal = "load" })
T.falsy(appliedPreset, "opening the preset browser does not apply a preset")
local explorer = window.editor.itemExplorer
T.equal(explorer.options.mode, "preset", "presets use the contextual shared browser")
local portraitProviders = 0
function session:GetContext() return { playerSurname = 'patz' } end
package.loaded['PNC/UI/NPCAuthoring/PNC_NPCAuthoringPresetPreview'] = {
    Companions = function(payload, context, _, target)
        portraitProviders = portraitProviders + 1
        T.equal(payload.companionTraitID, sister, 'browser previews the saved file instead of the edited NPC')
        T.equal(context.playerSurname, 'patz', 'preview receives current inheritance context')
        T.equal(target, brother, 'preview uses the selected companion policy')
        return function() return { key = 'saved-sister' }, 'Jane patz', 1 end
    end,
}
T.equal(explorer.options.preview(explorer.options.items[1], 1).key, 'saved-sister', 'host supplies a portrait for preset selection')
explorer.options.preview(explorer.options.items[1], 1)
T.equal(portraitProviders, 1, 'reselecting a saved record reuses its read-only provider')
T.falsy(appliedPreset, 'previewing a saved record never applies it to the current companions')
explorer.options.onChoose(explorer.options.items[1])
explorer:Hide()
T.equal(appliedPreset.companionTraitID, sister, "explicit browser apply loads the selected preset")
T.equal(appliedOptions.targetTraitID, brother, "loading a template targets the selected companion")
T.truthy(appliedOptions.activeOnly, "UI preset loads operate on active slots")
T.equal(window.selectedTraitID, brother, "template load refreshes the selected companion")
T.equal(window.statusText, "Preset loaded", "successful load gives visible feedback")

window.editor.onSelectRoster(nil)
T.falsy(window.selectedTraitID, "invalid selection clears selected trait")
T.falsy(window.adapter, "invalid selection detaches the adapter")
T.falsy(window.editor.form, "invalid selection clears the form")
T.falsy(window.editor.portraitTarget, "invalid selection clears the portrait")
T.equal(window.statusText, "No starting companion trait selected",
    "invalid selection explains the cleared state")

window.editor.onSelectRoster(brother)
T.equal(window.selectedTraitID, brother,
    "a later valid selection restores the cleared companion transaction")
T.equal(window.editor.form.gender, "Male",
    "rebinding after an invalid selection restores the shared form")
T.equal(window.editor.portraitTarget.traitID, brother,
    "rebinding after an invalid selection restores the portrait target")

T.truthy(UIState, "starting companion UI state remains loadable")
window.editor.draft = { displayName = 'Lemuel Colbert' }
T.equal(window:currentLabel(), 'Lemuel Colbert', 'the real host defaults single-character saves to the NPC name rather than the relationship trait')
-- Saving a reusable copy has an explicit single-NPC/whole-roster scope.
local prompt, persisted
package.loaded['PNC/UI/NPCAuthoring/PNC_NPCAuthoringSaveDialog'] = {
    Open = function(_, name, library, callback, options)
        prompt = { name = name, library = library, callback = callback, title = options.title }
    end,
}
PNC.NPCAuthoring = { Registry = { Copy = function(value)
    return { displayName = value.displayName }
end } }
function window.editor:effectiveDraft() return self.draft end
function window:saveTemplate(label, filename, library, prepared)
    persisted = { label = label, filename = filename, library = library, prepared = prepared }
    return true
end
function window:saveSet(label, filename, preset)
    persisted = { label = label, filename = filename, preset = preset }
    return true
end
window:onAction({ internal = 'save' })
T.equal(prompt.title, 'Save NPC preset...', 'single-character action names its reusable scope')
T.equal(prompt.name, 'Lemuel Colbert', 'single-character prompt defaults to selected NPC')
window.editor.draft.displayName = 'Changed after prompt'
prompt.callback('Lemuel', 'Lemuel.txt', false)
T.equal(persisted.prepared.draft.displayName, 'Lemuel Colbert', 'save retains the reviewed NPC snapshot')
T.equal(persisted.library, false, 'preset-only save remains available')
window:onAction({ internal = 'load' })
T.truthy(window.editor.itemExplorer.options.contextAction, 'Presets owns the roster-save action')
window.editor.itemExplorer.options.contextAction.onClick()
T.equal(prompt.title, 'Save roster preset...', 'roster action names its whole-roster scope')
T.equal(prompt.library, nil, 'roster does not offer single-NPC encounter publication')
prompt.callback('My roster', 'My_roster.txt')
T.equal(persisted.preset.kind, 'whole', 'roster save serializes the whole set')
T.truthy(window.editor.itemExplorer.visible, 'saving a roster returns to its preset browser')

window.editor.pullForm = function() return false end
window:close()
T.falsy(window.removed, 'native close cannot dismiss the composer')
window:finish()
T.falsy(window.removed, 'Done leaves an invalid pending edit visible for correction')
window.editor.pullForm = function() return true end
local stopped = false
window.editor.appearanceTab = { onStopVoice = function() stopped = true end }
window:finish()
T.truthy(window.removed, 'Done returns to character creation after committing valid edits')
T.truthy(stopped, 'Done releases voice preview')
local mounted = {}
getCore = function()
    return { getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end }
end
ISPanel = {}
function ISPanel:new()
    local panel = { width = 1, height = 1 }
    function panel:initialise() end
    function panel:instantiate() end
    function panel:setWidth(value) self.width = value end
    function panel:setHeight(value) self.height = value end
    function panel:setVisible(value) self.visible = value end
    function panel:addChild(child) self.child = child end
    function panel:removeChild(child) if self.child == child then self.child = nil end end
    function panel:addToUIManager() mounted[#mounted + 1] = self end
    function panel:removeFromUIManager() self.unmounted = true end
    function panel:bringToTop() self.onTop = true end
    return panel
end
UI.NewWindow = function(class, options)
    local created = class:new(0, 0, 1060, 800, options)
    function created:instantiate() self:createChildren() end
    function created:addToUIManager() mounted[#mounted + 1] = self end
    return created
end
local modal = assert(UIState.Open(session))
local root = modal.modalRoot
T.equal(#mounted, 1, "only the modal root is registered at the top level")
T.equal(mounted[1], root)
T.equal(root.child, modal, "native child dispatch reaches the composer before the backdrop")
T.truthy(root.onMouseDown(), "clicks outside the composer are consumed")
T.equal(root.width, 1920)
modal:onAction({ internal = "done" })
T.truthy(root.unmounted, "Done unregisters the entire modal root")
T.falsy(UIState.IsOpen(), "closing the composer unlocks character creation")
T.finish("pnc_starting_companion_ui_interaction_smoke")
