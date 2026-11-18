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
function BaseWindow:getContentRect()
    return { x = 0, y = 0, width = self.width, height = self.height }
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

local appliedPreset
local Presets = {
    TemplateFromSession = function(_, traitID, label)
        return { kind = "template", companionTraitID = traitID, label = label }, nil
    end,
    FromSession = function() return { kind = "whole", label = "set" }, nil end,
    ApplyToSession = function(_, payload)
        appliedPreset = payload
        return { applied = { payload.companionTraitID or brother } }, nil
    end,
}
local Store = {}
function Store.List()
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
window:refresh()

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

window.presetCombo:selectData(selectedPreset)
window.presetCombo:invokeChange()
T.equal(window.selectedPresetFile, selectedPreset,
    "vanilla preset callback stores the visible preset")
window:onAction({ internal = "load" })
T.falsy(appliedPreset, "opening the preset browser does not apply a preset")
local explorer = window.editor.itemExplorer
T.equal(explorer.options.mode, "preset", "presets use the contextual shared browser")
explorer.options.onChoose(explorer.options.items[1])
explorer:Hide()
T.equal(appliedPreset.companionTraitID, sister, "explicit browser apply loads the selected preset")
T.equal(window.selectedTraitID, sister,
    "template load rebinds the same selected companion transaction")

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
T.finish("pnc_starting_companion_ui_interaction_smoke")
