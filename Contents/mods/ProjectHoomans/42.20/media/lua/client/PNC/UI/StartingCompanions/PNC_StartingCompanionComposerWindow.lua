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
    self.slotCombo = addCombo(self, self, function(combo)
        local option = combo.options and combo.options[combo.selected]
        self.selectedTraitID = option and option.data or nil
        self:refreshSelected()
    end)
    self.presetCombo = addCombo(self, self, function(combo)
        local option = combo.options and combo.options[combo.selected]
        self.selectedPresetFile = option and option.data or nil
    end)

    self.loadButton = UI.CreateButton(self, {
        id = "load", title = tr("UI_PNC_StartingCompanion_Load", "LOAD"),
        target = self, onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "quiet",
    })
    self.saveButton = UI.CreateButton(self, {
        id = "save", title = tr("UI_PNC_StartingCompanion_Save", "SAVE"),
        target = self, onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "quiet",
    })
    self.saveSetButton = UI.CreateButton(self, {
        id = "save_set",
        title = tr("UI_PNC_StartingCompanion_SaveSet", "SAVE SET"),
        target = self, onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "primary",
    })
    self.randomizeButton = UI.CreateButton(self, {
        id = "randomize",
        title = tr("UI_PNC_StartingCompanion_Randomize", "RANDOMIZE"),
        target = self, onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "selected",
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
        title = tr("UI_PNC_StartingCompanion_Close", "CLOSE"),
        target = self, onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "quiet",
    })
    self.summary = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(25, self.uiScale),
        labelWidthRatio = 0.42,
        valueXRatio = 0.44,
    })
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
end

function ISPNCStartingCompanionComposerWindow:setStatus(value)
    self.statusText = tostring(value or "")
    if UI.SetLabelText then
        UI.SetLabelText(self.statusLabel, self.statusText)
    elseif self.statusLabel then
        self.statusLabel:setName(self.statusText)
    end
end

function ISPNCStartingCompanionComposerWindow:refreshSlots()
    local active = self.session and self.session.GetActiveSlots
        and self.session:GetActiveSlots() or {}
    local selected = self.selectedTraitID
    self.slotCombo:clear()
    for _, slot in ipairs(active) do
        local spec = slot.spec or StartingTraits.GetDefinition(slot.traitID)
        local label = spec and tr(spec.uiName, spec.relationshipKind)
            or tr("UI_PNC_StartingCompanion_Companion", "Companion")
        self.slotCombo:addOptionWithData(label, slot.traitID)
        if not selected then selected = slot.traitID end
    end
    self.selectedTraitID = selected
    if selected then self.slotCombo:selectData(selected) end
end

function ISPNCStartingCompanionComposerWindow:refreshPresets()
    local selected = self.selectedPresetFile
    self.presetCombo:clear()
    self.presetCombo:addOptionWithData(
        tr("UI_PNC_StartingCompanion_NoPreset", "No saved preset"), nil)
    for _, entry in ipairs(Store.List()) do
        self.presetCombo:addOptionWithData(
            tostring(entry.label or entry.fileName), entry.fileName)
    end
    self.selectedPresetFile = selected
    if selected then self.presetCombo:selectData(selected) end
end

function ISPNCStartingCompanionComposerWindow:refreshSelected()
    if not self.session or not self.selectedTraitID then
        self.editor:setAdapter(nil)
        self:refreshSummary()
        self:setStatus(tr("UI_PNC_StartingCompanion_NoSelection",
            "No starting companion trait selected"))
        return
    end
    self.adapter = Adapter.New(self.session, self.selectedTraitID)
    self.editor:setAdapter(self.adapter)
    self:refreshSummary()
end

function ISPNCStartingCompanionComposerWindow:refreshSummary()
    self.summary:clear()
    if not self.session then return end
    for _, item in ipairs(self.session:FinalSummary()) do
        addListItem(self.summary,
            relationshipLabel(item.relationshipKind),
            item.displayName or tr("UI_PNC_StartingCompanion_PreviewUnavailable",
                "Preview unavailable"),
            item.error ~= nil)
    end
end

function ISPNCStartingCompanionComposerWindow:refresh()
    self:refreshSlots()
    self:refreshPresets()
    self:refreshSelected()
    self:refreshSummary()
    self:onResponsiveLayout()
end

function ISPNCStartingCompanionComposerWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 0, bottom = 10 })
    local gap = Layout.Pixels(8, self.uiScale)
    local rowHeight = Layout.Pixels(28, self.uiScale)
    local slotWidth = math.floor((rect.width - gap) * 0.48)
    local presetWidth = rect.width - slotWidth - gap
    local y = rect.y
    local actions = {
        self.loadButton, self.saveButton, self.saveSetButton,
        self.randomizeButton, self.resetButton, self.revertButton,
        self.closeButton,
    }
    Layout.SetBounds(self.slotCombo, rect.x, y, slotWidth, rowHeight)
    Layout.SetBounds(self.presetCombo, rect.x + slotWidth + gap, y,
        presetWidth, rowHeight)
    y = y + rowHeight + gap
    local actionWidth = math.max(Layout.Pixels(78, self.uiScale),
        math.floor((rect.width - gap * (#actions - 1)) / #actions))
    local actionX = rect.x
    for _, control in ipairs(actions) do
        Layout.SetBounds(control, actionX, y, actionWidth, rowHeight)
        actionX = actionX + actionWidth + gap
    end
    y = y + rowHeight + gap
    local statusHeight = Layout.Pixels(18, self.uiScale)
    local summaryHeight = Layout.Pixels(82, self.uiScale)
    local summaryY = rect.y + rect.height - summaryHeight
        - statusHeight - gap
    Layout.SetBounds(self.summary, rect.x, summaryY, rect.width, summaryHeight)
    local editorHeight = math.max(Layout.Pixels(220, self.uiScale),
        summaryY - gap - y)
    Layout.SetBounds(self.editor, rect.x, y, rect.width, editorHeight)
    self.editor.uiScale = self.uiScale
    self.editor:requestResponsiveLayout(true)
    Layout.SetBounds(self.statusLabel, rect.x,
        rect.y + rect.height - statusHeight, rect.width, statusHeight)
end

function ISPNCStartingCompanionComposerWindow:currentLabel()
    local slot = self.session and self.session:GetSlot(self.selectedTraitID, true)
    local spec = slot and slot.spec or nil
    return spec and tr(spec.uiName, spec.relationshipKind)
        or tr("UI_PNC_StartingCompanion_Companion", "Companion")
end

function ISPNCStartingCompanionComposerWindow:saveTemplate()
    local payload, reason = Presets.TemplateFromSession(self.session,
        self.selectedTraitID, self:currentLabel())
    if not payload then return false, reason end
    return Store.Save(payload, payload.label or self:currentLabel())
end

function ISPNCStartingCompanionComposerWindow:saveSet()
    local payload, reason = Presets.FromSession(self.session, "Starting companions")
    if not payload then return false, reason end
    return Store.Save(payload, payload.label or "Starting companions")
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
    if payload.kind == "template" then
        self.selectedTraitID = payload.companionTraitID
    end
    return true
end

function ISPNCStartingCompanionComposerWindow:onAction(button)
    local id = button and button.internal
    local ok
    local reason
    if id == "close" then
        self:close()
        return
    end
    if not self.session or not self.selectedTraitID then return end
    if id == "save" then
        ok, reason = self:saveTemplate()
        self:setStatus(ok and tr("UI_PNC_StartingCompanion_Saved",
            "Companion saved") or tostring(reason or "save failed"))
        if ok then self:refreshPresets() end
    elseif id == "save_set" then
        ok, reason = self:saveSet()
        self:setStatus(ok and tr("UI_PNC_StartingCompanion_SetSaved",
            "Companion set saved") or tostring(reason or "save failed"))
        if ok then self:refreshPresets() end
    elseif id == "load" then
        ok, reason = self:loadSelected()
        self:setStatus(ok and tr("UI_PNC_StartingCompanion_Loaded",
            "Preset loaded") or tostring(reason or "load failed"))
        if ok then self:refresh() end
    elseif id == "randomize" or id == "reset" or id == "revert" then
        ok = self.editor:invokeWorkflow(id)
        self:refreshSummary()
        if not ok and id == "revert" then
            self:setStatus(tr("UI_PNC_StartingCompanion_NoPresetBaseline",
                "No preset baseline is loaded"))
        end
    end
end

function ISPNCStartingCompanionComposerWindow:close()
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
