-- Starting-companion workflow host.
--
-- This window owns slot selection, presets, and relationship workflow. All
-- primitive NPC editing is delegated to the same NPCAuthoringEditor used by
-- the debug Unique NPC creator.

require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/PsychopatzFixedWindow"
require "ISUI/ISComboBox"
require "ISUI/ISLabel"
require "PNC/Core/Traits/PNC_StartingCompanionTraits"
require "PNC/CharacterCreation/PNC_StartingCompanionPresets"
require "PNC/CharacterCreation/PNC_StartingCompanionPresetStore"
require "PNC/CharacterCreation/PNC_StartingCompanionAuthoringAdapter"
require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringEditor"

PNC = PNC or {}
PNC.StartingCompanionComposerUI = PNC.StartingCompanionComposerUI or {}

local UIState = PNC.StartingCompanionComposerUI
local StartingTraits = PNC.StartingCompanionTraits
local Presets = PNC.StartingCompanionPresets
local Store = PNC.StartingCompanionPresetStore
local Adapter = PNC.StartingCompanionAuthoringAdapter
local UI = PsychopatzCore.UI
local Layout = UI.Layout

local function tr(key, fallback)
    if PNC.Translation and PNC.Translation.GetKey then
        return PNC.Translation.GetKey(key, fallback)
    end
    return fallback or key
end

local function addCombo(parent, target, callback)
    local combo = ISComboBox:new(0, 0, 1, 24)
    combo:initialise()
    combo:instantiate()
    combo.target = target
    combo.onChange = callback
    parent:addChild(combo)
    return combo
end

local function addListItem(list, label, value, warning)
    UI.AddKeyValue(list, label, value, { warning = warning == true })
end

local function relationshipLabel(kind)
    local keys = {
        brother = { "UI_PNC_Relationship_Brother", "Brother" },
        sister = { "UI_PNC_Relationship_Sister", "Sister" },
        mother = { "UI_PNC_Relationship_Mother", "Mother" },
        father = { "UI_PNC_Relationship_Father", "Father" },
        lover = { "UI_PNC_Relationship_Lover", "Lover" },
        friend = { "UI_PNC_Relationship_Friend", "Friend" },
    }
    local entry = keys[string.lower(tostring(kind or ""))]
    return entry and tr(entry[1], entry[2]) or tostring(kind or "Companion")
end

ISPNCStartingCompanionComposerWindow = PsychopatzFixedWindow:derive(
    "ISPNCStartingCompanionComposerWindow")

function ISPNCStartingCompanionComposerWindow:initialise()
    PsychopatzFixedWindow.initialise(self)
end

function ISPNCStartingCompanionComposerWindow:createChildren()
    PsychopatzFixedWindow.createChildren(self)
    -- ISComboBox invokes onChange as (target, combo, arg1, arg2).  Keep the
    -- callback boundary faithful to the vanilla widget and route all state
    -- changes through the bounded selection transactions below.
    self.presetCombo = addCombo(self, self, function(target, combo)
        local option = combo.options and combo.options[combo.selected]
        target:SelectPreset(option and option.data or nil)
    end)

    self.loadButton = UI.CreateButton(self, {
        id = "load", title = tr("UI_PNC_Authoring_Presets", "Presets..."),
        target = self, onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "quiet",
    })
    self.saveButton = UI.CreateButton(self, {
        id = "save", title = tr("UI_PNC_StartingCompanion_Save", "Save NPC preset..."),
        target = self, onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "quiet",
    })
    self.resetButton = UI.CreateButton(self, {
        id = "reset",
        title = tr("UI_PNC_StartingCompanion_Reset", "RESET"),
        target = self, onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "quiet",
    })
    self.revertButton = UI.CreateButton(self, {
        id = "revert",
        title = tr("UI_PNC_StartingCompanion_Revert", "REVERT TO PRESET"),
        target = self, onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "quiet",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close",
        title = tr("UI_PNC_StartingCompanion_Done", "Done"),
        target = self, onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "primary",
    })
    self.saveButton.tooltip = tr("UI_PNC_Authoring_SaveNPCHelp", "Save the selected NPC, including every tab and its loadout, as a reusable preset.")
    self.closeButton.tooltip = tr("UI_PNC_StartingCompanion_DoneHelp", "Keep your companion changes and return to character creation. Saving a reusable preset is optional.")
    self.statusLabel = ISLabel:new(0, 0, 24, "", 0.75, 0.8, 0.85, 1,
        UIFont.Small, true)
    self.statusLabel:initialise()
    self:addChild(self.statusLabel)
    self.editor = ISPNCNPCAuthoringEditor:new(0, 0, 1, 1, {
        mode = "companion",
        parent = self,
    })
    self.editor.uiScale = self.uiScale
    self.editor:initialise()
    self.editor:instantiate()
    self:addChild(self.editor)
    self.editor.refreshRosterSummary = function() self:refreshSummary() end
end

function ISPNCStartingCompanionComposerWindow:setStatus(value)
    self.statusText = tostring(value or "")
    if UI.SetLabelText then
        UI.SetLabelText(self.statusLabel, self.statusText)
    elseif self.statusLabel then
        self.statusLabel:setName(self.statusText)
    end
end

local function activeSlot(session, traitID)
    if not session or type(session.GetSlot) ~= "function" then return nil end
    return session:GetSlot(traitID, false)
end

function ISPNCStartingCompanionComposerWindow:SelectCompanion(traitID)
    local slot = activeSlot(self.session, traitID)
    local selectedID = slot and slot.traitID or nil

    if not selectedID then
        self.selectedTraitID = nil
        self.currentSelection = nil
        self.adapter = nil
        if self.editor then self.editor:setAdapter(nil) end
        self:refreshSummary()
        self:setStatus(tr("UI_PNC_StartingCompanion_NoSelection",
            "No starting companion trait selected"))
        return false, "slot_not_active"
    end

    self.selectedTraitID = selectedID
    self.adapter = Adapter.New(self.session, selectedID)
    self.currentSelection = {
        traitID = selectedID,
        relationshipKind = slot.spec and slot.spec.relationshipKind,
    }
    self.editor:setAdapter(self.adapter)
    self:refreshSummary()
    self:setStatus(self.editor.statusText
        or tr("UI_PNC_StartingCompanion_Ready", "Companion ready"))
    return true
end

function ISPNCStartingCompanionComposerWindow:SelectPreset(fileName)
    self.selectedPresetFile = fileName
    self.currentPresetFile = fileName
    if not self.presetCombo then return fileName end
    if fileName and self.presetCombo.selectData then
        self.presetCombo:selectData(fileName)
    elseif not fileName then
        self.presetCombo.selected = 1
    end
    return fileName
end

function ISPNCStartingCompanionComposerWindow:refreshSlots()
    local active = self.session and self.session.GetActiveSlots
        and self.session:GetActiveSlots() or {}
    local selected = self.selectedTraitID
    local selectedIsActive = false

    for _, slot in ipairs(active) do
        local spec = slot.spec or StartingTraits.GetDefinition(slot.traitID)
        local label = spec and tr(spec.uiName, spec.relationshipKind)
            or tr("UI_PNC_StartingCompanion_Companion", "Companion")

        if selected == slot.traitID then selectedIsActive = true end
        if not selected then selected = slot.traitID end
    end
    if #active == 0 then
        selected = nil
    elseif selected and not selectedIsActive then
        selected = active[1].traitID
    end
    self.selectedTraitID = selected

end

function ISPNCStartingCompanionComposerWindow:refreshPresets()
    local selected = self.selectedPresetFile
    local selectedIsAvailable = false
    self.presetCombo:clear()
    self.presetCombo:addOptionWithData(
        tr("UI_PNC_StartingCompanion_NoPreset", "No saved preset"), nil)
    for _, entry in ipairs(Store.List()) do
        if selected == entry.fileName then selectedIsAvailable = true end
        self.presetCombo:addOptionWithData(
            tostring(entry.label or entry.fileName), entry.fileName)
    end
    if not selectedIsAvailable then selected = nil end
    self:SelectPreset(selected)
end

function ISPNCStartingCompanionComposerWindow:refreshSelected()
    return self:SelectCompanion(self.selectedTraitID)
end

function ISPNCStartingCompanionComposerWindow:refreshSummary()
    local rows = {}
    for _, item in ipairs(self.session and self.session:FinalSummary() or {}) do
        rows[#rows + 1] = { id = item.traitID,
            label = item.displayName or relationshipLabel(item.relationshipKind),
            subtitle = relationshipLabel(item.relationshipKind), error = item.error }
    end
    self.editor:setRoster(rows, self.selectedTraitID, function(id)
        self:SelectCompanion(id)
    end)
end

function ISPNCStartingCompanionComposerWindow:refresh()
    self:refreshSlots()
    self:refreshPresets()
    self:refreshSelected()
    self:refreshSummary()
    self:onResponsiveLayout()
end

function ISPNCStartingCompanionComposerWindow:onResponsiveLayout()
    local rect = self:getContentRect({ bottom = 10 })
    local gap = Layout.Pixels(8, self.uiScale)
    local rowHeight = Layout.Pixels(28, self.uiScale)
    self.presetCombo:setVisible(false)
    local toolbar = Layout.Flow({
        self.loadButton, self.saveButton,
        self.resetButton, self.revertButton, self.closeButton,
    }, { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 78, gap = 6 })
    local exploring = self.editor and self.editor.itemExplorer and self.editor.itemExplorer:getIsVisible()
    for _, control in ipairs({ self.loadButton, self.saveButton, self.resetButton, self.revertButton, self.closeButton }) do PNC.NPCAuthoringFields.EnableButton(control, not exploring) end
    local y = toolbar.bottom + gap
    local statusHeight = Layout.Pixels(22, self.uiScale)
    Layout.SetBounds(self.editor, rect.x, y, rect.width,
        math.max(1, rect.y + rect.height - y - statusHeight - gap))
    self.editor.uiScale = self.uiScale
    self.editor:requestResponsiveLayout()
    PNC.NPCAuthoringFields.NativeMetrics(self)
    Layout.SetBounds(self.statusLabel, rect.x,
        rect.y + rect.height - statusHeight, rect.width, statusHeight)
end

function ISPNCStartingCompanionComposerWindow:currentLabel()
    if self.editor and self.editor.draft and tostring(self.editor.draft.displayName or "") ~= "" then return self.editor.draft.displayName end
    local slot = self.session and self.session:GetSlot(self.selectedTraitID, true)
    local spec = slot and slot.spec or nil
    return spec and tr(spec.uiName, spec.relationshipKind)
        or tr("UI_PNC_StartingCompanion_Companion", "Companion")
end

function ISPNCStartingCompanionComposerWindow:saveTemplate(label, fileName, library, prepared)
    local payload, reason
    if prepared then payload = prepared.preset; payload.label = label
    else payload, reason = Presets.TemplateFromSession(self.session, self.selectedTraitID, label or self:currentLabel()) end
    if not payload then return false, reason end
    local ok, saved = Store.Save(payload, payload.label or self:currentLabel(), fileName)
    if not ok then return false, saved end
    if library then
        local storage = require "PNC/Identity/PNC_UniqueNPCDefinitionStore"
        local exported, reason = storage.SaveCharacter(prepared and prepared.draft or self.editor:effectiveDraft(), fileName or Store.FileName(payload.label))
        if not exported then return false, tr("UI_PNC_Authoring_PresetOnlySaved", "Preset saved; encounter character could not be saved: ") .. tostring(reason) end
    end
    return true, saved
end

function ISPNCStartingCompanionComposerWindow:saveSet(label, fileName, prepared)
    local payload, reason
    if prepared then payload = prepared; payload.label = label
    else payload, reason = Presets.FromSession(self.session, label or tr("UI_PNC_StartingCompanion_Title", "Starting companions")) end
    if not payload then return false, reason end
    return Store.Save(payload, payload.label, fileName)
end

function ISPNCStartingCompanionComposerWindow:promptSaveSet()
    if not self.session then return false end
    if self.editor.draft and self.editor:pullForm() == false then return false end
    local preset, reason = Presets.FromSession(self.session)
    if not preset then self:setStatus(tostring(reason)); return false end
    local dialog = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringSaveDialog"
    dialog.Open(self, tr("UI_PNC_StartingCompanion_Title", "Starting companions"), nil, function(label, fileName)
        local saved, why = self:saveSet(label, fileName, preset)
        self:setStatus(saved and tr("UI_PNC_StartingCompanion_SetSaved", "Roster preset saved") or tostring(why))
        self:refreshPresets()
        local explorer = self.editor.itemExplorer
        if saved and explorer:getIsVisible() and explorer.options.mode == "preset" then self:browsePresets() end
    end, { title = tr("UI_PNC_StartingCompanion_SaveSet", "Save roster preset..."),
        help = tr("UI_PNC_Authoring_SaveRosterHelp", "Save all companions together as one reusable roster preset.") })
    return true
end

function ISPNCStartingCompanionComposerWindow:loadSelected()
    if not self.selectedPresetFile then
        return false, "preset_not_selected"
    end
    local payload, reason = Store.Load(self.selectedPresetFile)
    if not payload then return false, reason end
    local result
    result, reason = Presets.ApplyToSession(self.session, payload)
    if not result then return false, reason end
    local nextTraitID = payload.kind == "template"
        and payload.companionTraitID or self.selectedTraitID
    if activeSlot(self.session, nextTraitID) then
        self:SelectCompanion(nextTraitID)
    else
        self:refreshSelected()
    end
    return true
end

function ISPNCStartingCompanionComposerWindow:browsePresets()
    local function entries()
    local items = {}
    for _, entry in ipairs(Store.List()) do
        local label = tostring(entry.label or entry.fileName)
        items[#items + 1] = { id = entry.fileName, label = label, search = string.lower(label .. " " .. entry.fileName), category = entry.kind }
    end
    return items
    end
    local items = entries()
    self.editor.itemExplorer:Show({ mode = "preset", items = items,
        title = tr("UI_PNC_Authoring_Presets", "Presets..."),
        applyLabel = tr("UI_PNC_StartingCompanion_Load", "Load"),
        contextAction = {
            title = tr("UI_PNC_StartingCompanion_SaveSet", "Save roster preset..."),
            tooltip = tr("UI_PNC_Authoring_SaveRosterHelp", "Save all companions together as one reusable roster preset."),
            onClick = function() self:promptSaveSet() end,
        },
        reloadItems = entries,
        onDelete = function(item)
            local ok, reason = Store.Delete(item.id)
            if ok then
                if self.selectedPresetFile == item.id then self:SelectPreset(nil) end
                self:refreshPresets()
            end
            return ok, reason
        end,
        describe = function(item)
            local payload = Store.Load(item.id)
            return { { label = tr("UI_PNC_Authoring_PresetScope", "Preset scope"),
                value = payload and tr(payload.kind == "template" and "UI_PNC_Authoring_PresetSingle" or "UI_PNC_Authoring_PresetWhole",
                    payload.kind == "template" and "One companion" or "Whole companion set") or tr("UI_PNC_Authoring_UnavailableItem", "This item is unavailable") } }
        end,
        onChoose = function(item)
            self:SelectPreset(item.id)
            local ok, reason = self:loadSelected()
            if ok then self:refreshSummary() end
            return ok, reason
        end })
    self.editor.itemExplorer.onDismiss = function() self.editor:requestResponsiveLayout(); self:onResponsiveLayout() end
    self:onResponsiveLayout()
end

function ISPNCStartingCompanionComposerWindow:onAction(button)
    local id = button and button.internal
    local ok
    local reason
    if id == "randomize" then return false end
    if self.editor.itemExplorer and self.editor.itemExplorer:getIsVisible() then return false end
    if self.editor.draft and id ~= "reset" and id ~= "revert" and id ~= "load" and id ~= "close" then
        if self.editor:pullForm() == false then return end
    end
    if id == "close" then
        self:close()
        return
    end
    if not self.session then
        self:setStatus(tr("UI_PNC_StartingCompanion_NoSession",
            "Starting companion session unavailable"))
        return
    end
    if not self.selectedTraitID or not activeSlot(self.session, self.selectedTraitID) then
        self:SelectCompanion(nil)
        return
    end
    if id == "save" then
        local dialog = require "PNC/UI/NPCAuthoring/PNC_NPCAuthoringSaveDialog"
        local preset, why = Presets.TemplateFromSession(self.session, self.selectedTraitID, self:currentLabel())
        if not preset then self:setStatus(tostring(why)); return end
        local prepared = { preset = preset, draft = PNC.NPCAuthoring.Registry.Copy(self.editor:effectiveDraft()) }
        dialog.Open(self, self:currentLabel(), true, function(label, fileName, library)
            local saved, why = self:saveTemplate(label, fileName, library, prepared)
            self:setStatus(saved and tr("UI_PNC_StartingCompanion_Saved", "Companion saved") or tostring(why))
            self:refreshPresets()
        end, { title = tr("UI_PNC_StartingCompanion_Save", "Save NPC preset..."), help = self.saveButton.tooltip })
    elseif id == "save_set" then
        self:promptSaveSet()
    elseif id == "load" then
        self:browsePresets()
    elseif id == "reset" or id == "revert" then
        ok = self.editor:invokeWorkflow(id)
        self:refreshSummary()
        self:setStatus(self.editor.statusText
            or tr("UI_PNC_StartingCompanion_Ready", "Companion ready"))
        if not ok and id == "revert" then
            self:setStatus(tr("UI_PNC_StartingCompanion_NoPresetBaseline",
                "No preset baseline is loaded"))
        end
    end
end

function ISPNCStartingCompanionComposerWindow:close()
    if self.editor then
        if self.editor:pullForm() == false then return false end
        self.editor.appearanceTab:onStopVoice()
    end
    self:setVisible(false)
    self:removeFromUIManager()
    UIState.instance = nil
end

function ISPNCStartingCompanionComposerWindow:new(x, y, width, height, options)
    local object = PsychopatzFixedWindow.new(self, x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    object.session = options and options.session
    return object
end

function UIState.Open(session)
    if not session then return nil, "session_missing" end
    local window = UIState.instance
    if not window then
        window = UI.NewWindow(ISPNCStartingCompanionComposerWindow, {
            title = tr("UI_PNC_StartingCompanion_Title",
                "STARTING COMPANION COMPOSER"),
            session = session,
            resizable = true,
            responsiveSpec = {
                width = 1060, height = 800, minWidth = 820, minHeight = 620,
                maxWidth = 1600, maxHeight = 1100,
            },
        })
        window:initialise()
        window:instantiate()
        window:addToUIManager()
        UIState.instance = window
    else
        window.session = session
        window:addToUIManager()
        window:setVisible(true)
        window:bringToTop()
    end
    window:refresh()
    return window
end

function UIState.Close()
    if UIState.instance then UIState.instance:close() end
end

return UIState
