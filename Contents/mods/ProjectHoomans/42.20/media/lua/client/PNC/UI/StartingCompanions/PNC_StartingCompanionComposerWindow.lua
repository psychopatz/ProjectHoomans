-- Small presentation surface over the reusable NPC authoring composer.
-- Field rows, source labels, and mutations come from the canonical registry,
-- blueprint, policy, and resolver trace; this window owns no NPC schema.

require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISComboBox"
require "ISUI/ISLabel"
require "PNC/CharacterCreation/PNC_StartingCompanionComposer"

PNC = PNC or {}
PNC.StartingCompanionComposerUI = PNC.StartingCompanionComposerUI or {}

local UIState = PNC.StartingCompanionComposerUI
local Composer = PNC.NPCAuthoringComposer
local UI = PsychopatzCore.UI
local Layout = UI.Layout

local function tr(key, fallback)
    if PNC.Translation and PNC.Translation.GetKey then
        return PNC.Translation.GetKey(key, fallback)
    end
    return fallback or key
end

local function text(value)
    if value == nil then return "-" end
    if type(value) == "table" then
        return "<" .. tostring(type(value)) .. ">"
    end
    return tostring(value)
end

local function addListItem(list, label, value, warning)
    list:addItem(tostring(label or ""), {
        label = tostring(label or ""),
        value = tostring(value or "-"),
        warning = warning == true,
    })
end

ISPNCStartingCompanionComposerWindow = PsychopatzWindow:derive(
    "ISPNCStartingCompanionComposerWindow")

function ISPNCStartingCompanionComposerWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCStartingCompanionComposerWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.slotCombo = ISComboBox:new(0, 0, 1, 24)
    self.slotCombo:initialise()
    self.slotCombo:instantiate()
    self.slotCombo.target = self
    self.slotCombo.onChange = function(combo)
        local option = combo.options and combo.options[combo.selected]
        self.selectedTraitID = option and option.data or nil
        self:refreshDetails()
    end
    self:addChild(self.slotCombo)

    self.randomizeButton = UI.CreateButton(self, {
        id = "randomize",
        title = tr("UI_PNC_StartingCompanion_Randomize", "RANDOMIZE"),
        target = self,
        onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "selected",
    })
    self.resetButton = UI.CreateButton(self, {
        id = "reset",
        title = tr("UI_PNC_StartingCompanion_Reset", "RESET"),
        target = self,
        onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "quiet",
    })
    self.revertButton = UI.CreateButton(self, {
        id = "revert",
        title = tr("UI_PNC_StartingCompanion_Revert", "REVERT TO PRESET"),
        target = self,
        onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "quiet",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close",
        title = tr("UI_PNC_StartingCompanion_Close", "CLOSE"),
        target = self,
        onclick = ISPNCStartingCompanionComposerWindow.onAction,
        variant = "quiet",
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(26, self.uiScale),
        labelWidthRatio = 0.46,
        valueXRatio = 0.48,
    })
    self.summary = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(26, self.uiScale),
        labelWidthRatio = 0.46,
        valueXRatio = 0.48,
    })
    self.editPanel = UI.CreatePanel(self)
    self.editorRows = {}
    self.statusLabel = ISLabel:new(0, 0, 24, "", 0.75, 0.8, 0.85, 1,
        UIFont.Small, true)
    self.statusLabel:initialise()
    self:addChild(self.statusLabel)
end

function ISPNCStartingCompanionComposerWindow:onResponsiveLayout()
    local width = self:getWidth()
    local height = self:getHeight()
    local margin = Layout.Pixels(12, self.uiScale)
    local toolbarHeight = Layout.Pixels(30, self.uiScale)
    local half = math.floor((width - margin * 3) / 2)
    self.slotCombo:setX(margin)
    self.slotCombo:setY(margin)
    self.slotCombo:setWidth(math.max(160, half))
    self.slotCombo:setHeight(toolbarHeight)
    self.randomizeButton:setX(margin + half + margin)
    self.randomizeButton:setY(margin)
    self.randomizeButton:setWidth(Layout.Pixels(120, self.uiScale))
    self.randomizeButton:setHeight(toolbarHeight)
    self.resetButton:setX(margin + half + margin + 126)
    self.resetButton:setY(margin)
    self.resetButton:setWidth(Layout.Pixels(80, self.uiScale))
    self.resetButton:setHeight(toolbarHeight)
    self.revertButton:setX(margin + half + margin + 212)
    self.revertButton:setY(margin)
    self.revertButton:setWidth(Layout.Pixels(150, self.uiScale))
    self.revertButton:setHeight(toolbarHeight)
    self.closeButton:setX(width - margin - Layout.Pixels(80, self.uiScale))
    self.closeButton:setY(height - margin - toolbarHeight)
    self.closeButton:setWidth(Layout.Pixels(80, self.uiScale))
    self.closeButton:setHeight(toolbarHeight)
    self.details:setX(margin)
    self.details:setY(margin + toolbarHeight + margin + Layout.Pixels(216, self.uiScale))
    self.details:setWidth(half)
    self.details:setHeight(height - toolbarHeight * 2 - margin * 4
        - Layout.Pixels(216, self.uiScale))
    self.summary:setX(margin * 2 + half)
    self.summary:setY(margin + toolbarHeight + margin)
    self.summary:setWidth(half)
    self.summary:setHeight(height - toolbarHeight * 2 - margin * 3)
    self.editPanel:setX(margin)
    self.editPanel:setY(margin + toolbarHeight + margin)
    self.editPanel:setWidth(half)
    self.editPanel:setHeight(Layout.Pixels(216, self.uiScale))
    for index, row in ipairs(self.editorRows or {}) do
        row:place(0, (index - 1) * Layout.Pixels(26, self.uiScale),
            self.editPanel:getWidth(), Layout.Pixels(25, self.uiScale),
            { scale = self.uiScale })
    end
    self.statusLabel:setX(margin)
    self.statusLabel:setY(height - margin - toolbarHeight)
    self.statusLabel:setWidth(width - margin * 3 - 80)
    self.statusLabel:setHeight(toolbarHeight)
end

function ISPNCStartingCompanionComposerWindow:refreshSlots()
    local session = self.session
    local active = session and session.GetActiveSlots
        and session:GetActiveSlots() or {}
    local selected = self.selectedTraitID
    self.slotCombo:clear()
    for _, slot in ipairs(active) do
        self.slotCombo:addOptionWithData(
            tostring(slot.spec.uiName or slot.traitID), slot.traitID)
        if not selected then selected = slot.traitID end
    end
    self.selectedTraitID = selected
    if selected then self.slotCombo:selectData(selected) end
end

function ISPNCStartingCompanionComposerWindow:refreshDetails()
    local session = self.session
    local traitID = self.selectedTraitID
    local composer
    local rows
    local summary
    self.details:clear()
    self.summary:clear()
    for _, row in ipairs(self.editorRows or {}) do row:setVisible(false) end
    self.editorRows = {}
    if not session or not traitID then
        self.statusLabel:setName(tr("UI_PNC_StartingCompanion_NoSelection",
            "No starting companion trait selected"))
        return
    end
    composer = Composer.New({ session = session, traitID = traitID })
    rows = composer:FieldRows(48)
    local editorCount = 0
    for _, row in ipairs(rows) do
        if row.visible then
            addListItem(self.details,
                row.fieldID .. " · " .. row.sourceLabel,
                text(row.resolvedValue or row.authoredValue)
                    .. " [" .. row.state .. "]",
                row.clearIgnored)
            if row.editable and (row.valueType == "string"
                or row.valueType == "number") and editorCount < 8
            then
                editorCount = editorCount + 1
                local current = row.authoredValue
                local fieldID = row.fieldID
                local valueType = row.valueType
                local formRow = UI.CreateFormRow(self.editPanel, {
                    id = "field_" .. fieldID,
                    label = row.fieldID .. " · " .. row.sourceLabel,
                    valueLabel = true,
                    valueText = row.sourceLabel,
                    createControl = function(parent)
                        return UI.CreateTextEntry(parent, {
                            text = current == nil and "" or tostring(current),
                            onlyNumbers = valueType == "number",
                            maxTextLength = 160,
                            onTextChange = function(entry)
                                local input = entry and entry:getText() or ""
                                if input == "" and row.clearable then
                                    composer:ClearField(fieldID)
                                elseif input ~= "" then
                                    local value = valueType == "number"
                                        and tonumber(input) or input
                                    if value ~= nil then
                                        composer:SetField(fieldID, value)
                                    end
                                end
                                self:refreshDetails()
                            end,
                        })
                    end,
                })
                formRow:place(0,
                    (editorCount - 1) * Layout.Pixels(26, self.uiScale),
                    self.editPanel:getWidth(),
                    Layout.Pixels(25, self.uiScale),
                    { scale = self.uiScale })
                self.editorRows[#self.editorRows + 1] = formRow
            end
        end
    end
    self.editPanel:setVisible(editorCount > 0)
    summary = session:FinalSummary()
    for _, item in ipairs(summary) do
        addListItem(self.summary,
            item.traitID .. " · " .. tostring(item.relationshipKind),
            item.displayName or tr("UI_PNC_StartingCompanion_PreviewUnavailable",
                "preview unavailable"),
            item.error ~= nil)
    end
    self.statusLabel:setName(
        tr("UI_PNC_StartingCompanion_IntentHint",
            "Blueprint / Intent is separate from the Resolved Preview"))
end

function ISPNCStartingCompanionComposerWindow:refresh()
    self:refreshSlots()
    self:refreshDetails()
    self:onResponsiveLayout()
end

function ISPNCStartingCompanionComposerWindow:onAction(button)
    local id = button and button.internal
    if id == "close" then
        self:close()
        return
    end
    if not self.session or not self.selectedTraitID then return end
    if id == "randomize" then
        self.session:RandomizeSlot(self.selectedTraitID)
    elseif id == "reset" then
        self.session:ResetSlot(self.selectedTraitID)
    elseif id == "revert" then
        self.session:RevertToPreset(self.selectedTraitID)
    end
    self:refreshDetails()
end

function ISPNCStartingCompanionComposerWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    UIState.instance = nil
end

function ISPNCStartingCompanionComposerWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
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
                width = 960, height = 640, minWidth = 760, minHeight = 480,
                maxWidth = 1600, maxHeight = 1000,
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
