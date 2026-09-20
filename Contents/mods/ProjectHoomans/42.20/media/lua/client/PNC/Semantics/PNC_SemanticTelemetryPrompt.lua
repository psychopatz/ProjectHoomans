-- Client prompt shown when the semantic policy asks the player to clarify.
require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISComboBox"
require "ISUI/ISLabel"
require "PNC/Semantics/PNC_SemanticDialoguePolicy"
require "PNC/Semantics/PNC_SemanticTelemetryStorage"

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local TelemetryPrompt = PNC.Semantics.SemanticTelemetryPrompt or {}
PNC.Semantics.SemanticTelemetryPrompt = TelemetryPrompt

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Storage = PNC.Semantics.SemanticTelemetryStorage
local NEW_SEMANTIC = "__REQUEST_NEW_SEMANTIC__"

TelemetryPrompt.Queue = TelemetryPrompt.Queue or {}
TelemetryPrompt.Seen = TelemetryPrompt.Seen or {}
TelemetryPrompt.SeenOrder = TelemetryPrompt.SeenOrder or {}

local function tr(name, fallback)
    local translation = PNC and PNC.Translation
    local key = "UI_PNC_Conversation_Telemetry_" .. tostring(name)
    if translation and type(translation.GetKey) == "function" then
        return translation.GetKey(key, fallback)
    end
    return fallback or key
end

local function trim(value)
    local output = tostring(value or "")
    output = string.gsub(output, "^%s+", "")
    output = string.gsub(output, "%s+$", "")
    return output
end

local function addLabel(parent, value, muted)
    local label = ISLabel:new(0, 0, 20, tostring(value or ""),
        0.82, 0.86, 0.91, 1, UIFont.Small, true)
    label:initialise()
    if muted and UI.SetLabelTheme then
        UI.SetLabelTheme(label, "textMuted")
    end
    parent:addChild(label)
    return label
end

local function addTextEntry(parent, definition, multiLine, editable)
    local entry = UI.CreateTextEntry(parent, definition)
    if multiLine and entry.setMultipleLine then
        entry:setMultipleLine(true)
    end
    if multiLine and entry.setMaxLines then
        entry:setMaxLines(6)
    end
    if editable == false and entry.setEditable then
        entry:setEditable(false)
        if entry.setSelectable then entry:setSelectable(true) end
    end
    return entry
end

local function selectedData(combo)
    local index = combo and combo.getSelected
        and combo:getSelected() or combo and combo.selected
    if type(index) ~= "number" or index < 1 then return nil end
    local option = combo.options and combo.options[index]
    return option and option.data or nil
end

local function actionLabel(action)
    local label = string.lower(tostring(action or ""))
    label = string.gsub(label, "_", " ")
    return string.upper(string.sub(label, 1, 1)) .. string.sub(label, 2)
end

local TelemetryPromptWindow = UI.Window:derive(
    "PNCSemanticTelemetryPromptWindow")

function TelemetryPromptWindow:createChildren()
    UI.Window.createChildren(self)

    self.questionLabel = addLabel(self, tr("Question",
        "What were you trying to do?"))
    self.explanationEntry = addTextEntry(self, {
        text = tr("Explain",
            "I couldn't match that sentence to a supported action. Tell us what you meant.")
            .. " " .. tr("LocalOnly",
                "Press Send to save a local report. It is not uploaded automatically."),
        maxTextLength = 512,
    }, true, false)
    self.sentenceLabel = addLabel(self, tr("SentenceLabel",
        "Sentence the system could not understand:"), true)
    self.sentenceEntry = addTextEntry(self, {
        text = self.report and self.report.rawText or "",
        maxTextLength = 4096,
    }, true, false)
    self.outcomeLabel = addLabel(self, tr("OutcomeLabel",
        "Help us identify what the sentence should mean."), true)
    self.actionLabel = addLabel(self, tr("ActionLabel",
        "Choose the closest supported semantic:"))

    self.actionCombo = ISComboBox:new(0, 0, 1, 1, self,
        TelemetryPromptWindow.onActionChanged)
    self.actionCombo:initialise()
    self.actionCombo:instantiate()
    self:addChild(self.actionCombo)
    self.actionCombo:addOption(tr("SelectSemantic",
        "Select a supported semantic..."))

    local policy = PNC.Semantics and PNC.Semantics.DialoguePolicy
    local actions = policy and type(policy.GetCommandActions) == "function"
        and policy.GetCommandActions() or {}
    for _, action in ipairs(actions) do
        self.actionCombo:addOptionWithData(
            tr("Action_" .. tostring(action), actionLabel(action)), action)
    end
    self.actionCombo:addOptionWithData(
        tr("RequestNew", "Request a new semantic"), NEW_SEMANTIC)
    self.actionCombo.selected = 1

    self.newSemanticLabel = addLabel(self, tr("NewSemanticLabel",
        "Describe the new semantic you want:"))
    self.newSemanticEntry = addTextEntry(self, {
        text = "",
        maxTextLength = 128,
    }, false, true)
    if self.newSemanticEntry.setPlaceholderText then
        self.newSemanticEntry:setPlaceholderText(tr("NewSemanticPlaceholder",
            "Example: patrol this street until sunset"))
    end
    self.newSemanticLabel:setVisible(false)
    self.newSemanticEntry:setVisible(false)

    self.detailsLabel = addLabel(self, tr("DetailsLabel",
        "Extra details (optional):"))
    self.detailsEntry = addTextEntry(self, {
        text = "",
        maxTextLength = 2048,
    }, true, true)
    if self.detailsEntry.setPlaceholderText then
        self.detailsEntry:setPlaceholderText(tr("DetailsPlaceholder",
            "What did you expect the NPC to do?"))
    end

    self.privacyEntry = addTextEntry(self, {
        text = tr("Privacy",
            "The report contains your sentence, its semantic result, and your answers. It does not add player/NPC IDs or earlier conversation messages."),
        maxTextLength = 512,
    }, true, false)
    self.statusLabel = addLabel(self, "", true)

    local sendLabel = tr("Send", "Send report")
    self.sendButton = UI.CreateButton(self, {
        id = "send_semantic_telemetry",
        title = sendLabel,
        target = self,
        onclick = TelemetryPromptWindow.onSend,
        variant = "primary",
    })
    self.cancelButton = UI.CreateButton(self, {
        id = "cancel_semantic_telemetry",
        title = tr("Cancel", "Cancel"),
        target = self,
        onclick = TelemetryPromptWindow.onCancel,
        variant = "quiet",
    })

    self.savedTitleLabel = addLabel(self, tr("SavedTitle",
        "Telemetry report saved"))
    self.savedPathLabel = addLabel(self, tr("SavedPathLabel",
        "Saved file:"), true)
    self.savedPathEntry = addTextEntry(self, {
        text = "",
        maxTextLength = 256,
    }, false, false)
    self.instructionsLabel = addLabel(self, tr("InstructionsLabel",
        "To send it to the Project Hoomans modder:"), true)
    self.instructionsEntry = addTextEntry(self, {
        text = "",
        maxTextLength = 1024,
    }, true, false)
    self.closeButton = UI.CreateButton(self, {
        id = "close_semantic_telemetry",
        title = tr("Close", "Close"),
        target = self,
        onclick = TelemetryPromptWindow.onCancel,
        variant = "quiet",
    })

    self.formWidgets = {
        self.questionLabel, self.explanationEntry, self.sentenceLabel,
        self.sentenceEntry, self.outcomeLabel, self.actionLabel,
        self.actionCombo, self.newSemanticLabel, self.newSemanticEntry,
        self.detailsLabel, self.detailsEntry, self.privacyEntry,
        self.statusLabel, self.sendButton, self.cancelButton,
    }
    self.savedWidgets = {
        self.savedTitleLabel, self.savedPathLabel, self.savedPathEntry,
        self.instructionsLabel, self.instructionsEntry, self.closeButton,
    }
    for _, widget in ipairs(self.savedWidgets) do
        widget:setVisible(false)
    end
    self:requestResponsiveLayout(true)
end

function TelemetryPromptWindow:onActionChanged(combo)
    local isNew = selectedData(combo) == NEW_SEMANTIC
    self.newSemanticLabel:setVisible(isNew)
    self.newSemanticEntry:setVisible(isNew)
    self:requestResponsiveLayout(true)
end

function TelemetryPromptWindow:onSend()
    local semantic = selectedData(self.actionCombo)
    if not semantic then
        UI.SetLabelText(self.statusLabel, tr("ChooseSemanticError",
            "Choose the action you meant."))
        return
    end

    local isNew = semantic == NEW_SEMANTIC
    local proposedSemantic = isNew and trim(self.newSemanticEntry:getText())
        or nil
    if isNew and proposedSemantic == "" then
        UI.SetLabelText(self.statusLabel, tr("NewSemanticError",
            "Describe the new semantic before sending."))
        return
    end

    local outcome = self.report and self.report.outcome or {}
    local saved, fileName, path = Storage.Save({
        rawText = self.report and self.report.rawText,
        normalizedText = self.report and self.report.normalizedText,
        outcome = outcome,
        source = self.report and self.report.source,
        selectedSemantic = isNew and "REQUEST_NEW_SEMANTIC" or semantic,
        requestedNewSemantic = isNew,
        proposedSemantic = proposedSemantic,
        details = self.detailsEntry:getText(),
    })
    if not saved then
        UI.SetLabelText(self.statusLabel, tr("SaveError",
            "The report could not be saved. Check that the game can write files."))
        return
    end

    self.savedPath = path or ("Hoomans/Telemetry/" .. tostring(fileName))
    local instructions = {
        tr("Instruction1",
            "1. Find this file in your Project Zomboid Lua folder under Hoomans/Telemetry."),
        tr("Instruction2",
            "2. Open Project Hoomans on the Steam Workshop and choose Discussions."),
        tr("Instruction3",
            "3. Post in the telemetry or feedback discussion and attach this JSON file, or paste its contents."),
    }
    local instructionSeparator = "\n\n"
    self.instructionsEntry:setText(table.concat(
        instructions, instructionSeparator))
    self.savedPathEntry:setText(self.savedPath)
    self.mode = "saved"
    for _, widget in ipairs(self.formWidgets) do
        widget:setVisible(false)
    end
    for _, widget in ipairs(self.savedWidgets) do
        widget:setVisible(true)
    end
    self:requestResponsiveLayout(true)
end

function TelemetryPromptWindow:finish()
    self:close()
end

function TelemetryPromptWindow:onCancel()
    self:finish()
end

function TelemetryPromptWindow:close()
    if TelemetryPrompt.Active == self then
        TelemetryPrompt.Active = nil
    end
    self:setVisible(false)
    self:removeFromUIManager()
    TelemetryPrompt.ShowNext()
end

function TelemetryPromptWindow:onResponsiveLayout()
    if not self.questionLabel then return end
    local rect = self:getContentRect({ top = 34, bottom = 48,
        left = 14, right = 14 })
    local x, width = rect.x, rect.width
    local y = rect.y
    local small = Layout.Pixels(18, self.uiScale)
    local gap = Layout.Pixels(5, self.uiScale)

    if self.mode == "saved" then
        UI.Layout.SetBounds(self.savedTitleLabel,
            x, y, width, Layout.Pixels(24, self.uiScale))
        y = y + Layout.Pixels(32, self.uiScale)
        UI.Layout.SetBounds(self.savedPathLabel, x, y, width, small)
        y = y + small + gap
        UI.Layout.SetBounds(self.savedPathEntry,
            x, y, width, Layout.Pixels(30, self.uiScale))
        y = y + Layout.Pixels(38, self.uiScale)
        UI.Layout.SetBounds(self.instructionsLabel, x, y, width, small)
        y = y + small + gap
        UI.Layout.SetBounds(self.instructionsEntry,
            x, y, width, math.max(Layout.Pixels(120, self.uiScale),
                rect.y + rect.height - y))
        UI.Layout.SetBounds(self.closeButton,
            self:getWidth() - Layout.Pixels(104, self.uiScale),
            self:getHeight() - Layout.Pixels(38, self.uiScale),
            Layout.Pixels(90, self.uiScale), Layout.Pixels(28, self.uiScale))
        return
    end

    UI.Layout.SetBounds(self.questionLabel,
        x, y, width, Layout.Pixels(24, self.uiScale))
    y = y + Layout.Pixels(28, self.uiScale)
    UI.Layout.SetBounds(self.explanationEntry,
        x, y, width, Layout.Pixels(46, self.uiScale))
    y = y + Layout.Pixels(52, self.uiScale)
    UI.Layout.SetBounds(self.sentenceLabel, x, y, width, small)
    y = y + small + gap
    UI.Layout.SetBounds(self.sentenceEntry,
        x, y, width, Layout.Pixels(60, self.uiScale))
    y = y + Layout.Pixels(66, self.uiScale)
    UI.Layout.SetBounds(self.outcomeLabel, x, y, width, small)
    y = y + small + gap
    UI.Layout.SetBounds(self.actionLabel, x, y, width, small)
    y = y + small + gap
    UI.Layout.SetBounds(self.actionCombo,
        x, y, width, Layout.Pixels(28, self.uiScale))
    y = y + Layout.Pixels(33, self.uiScale)

    if selectedData(self.actionCombo) == NEW_SEMANTIC then
        UI.Layout.SetBounds(self.newSemanticLabel, x, y, width, small)
        y = y + small + gap
        UI.Layout.SetBounds(self.newSemanticEntry,
            x, y, width, Layout.Pixels(28, self.uiScale))
        y = y + Layout.Pixels(34, self.uiScale)
    end

    UI.Layout.SetBounds(self.detailsLabel, x, y, width, small)
    y = y + small + gap
    UI.Layout.SetBounds(self.detailsEntry,
        x, y, width, Layout.Pixels(94, self.uiScale))
    y = y + Layout.Pixels(100, self.uiScale)
    UI.Layout.SetBounds(self.privacyEntry,
        x, y, width, Layout.Pixels(44, self.uiScale))
    y = y + Layout.Pixels(48, self.uiScale)
    UI.Layout.SetBounds(self.statusLabel, x, y, width, small)

    local buttonY = self:getHeight() - Layout.Pixels(38, self.uiScale)
    UI.Layout.SetBounds(self.cancelButton,
        self:getWidth() - Layout.Pixels(214, self.uiScale), buttonY,
        Layout.Pixels(96, self.uiScale), Layout.Pixels(28, self.uiScale))
    UI.Layout.SetBounds(self.sendButton,
        self:getWidth() - Layout.Pixels(108, self.uiScale), buttonY,
        Layout.Pixels(96, self.uiScale), Layout.Pixels(28, self.uiScale))
end

function TelemetryPromptWindow:new(x, y, width, height, options)
    return UI.Window.new(self, x, y, width, height, options)
end

local function reportFrom(view, rawText, result, source)
    local ir = result and result.ir or {}
    local decision = result and result.decision or {}
    local provenance = ir.provenance or {}
    return {
        rawText = tostring(rawText or ""),
        normalizedText = tostring(ir.normalizedText or ""),
        source = source,
        outcome = {
            route = decision.route,
            branch = decision.branch,
            reason = decision.reason or result.reason,
            confidence = ir.confidence,
            intent = ir.intent,
            speechAct = ir.speechAct,
            action = ir.action,
            parser = provenance.parser,
            pattern = provenance.pattern,
            provider = result.provider or provenance.provider,
        },
    }
end

function TelemetryPrompt.ShowNext()
    if TelemetryPrompt.Active or #TelemetryPrompt.Queue == 0 then
        return false
    end
    local report = table.remove(TelemetryPrompt.Queue, 1)
    local windowCaption = tr("Title", "Semantic telemetry")
    local window = UI.NewWindow(TelemetryPromptWindow, {
        title = windowCaption,
        width = 540,
        height = 620,
        persistenceKey = false,
        persistGeometry = false,
        resizable = false,
        collapsible = false,
        responsiveSpec = {
            width = 540,
            height = 620,
            minWidth = 460,
            minHeight = 560,
            maxWidth = 620,
            maxHeight = 720,
            anchor = "bottom_right",
        },
    })
    window.report = report
    TelemetryPrompt.Active = window
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:bringToTop()
    if window.setAlwaysOnTop then window:setAlwaysOnTop(true) end
    return true
end

function TelemetryPrompt.Offer(view, rawText, result, source)
    if type(result) ~= "table" or type(result.decision) ~= "table"
        or result.decision.branch ~= "ASK_CLARIFICATION"
    then
        return false
    end
    local report = reportFrom(view, rawText, result, source)
    if report.rawText == "" then return false end

    local session = view and view.session
    local key = tostring(session and session.conversationID or "")
        .. ":" .. tostring(result.sequence or report.rawText)
    if TelemetryPrompt.Seen[key] then return false end
    if #TelemetryPrompt.Queue >= 8 then return false end
    if #TelemetryPrompt.SeenOrder >= 256 then
        local expired = table.remove(TelemetryPrompt.SeenOrder, 1)
        TelemetryPrompt.Seen[expired] = nil
    end
    TelemetryPrompt.Seen[key] = true
    TelemetryPrompt.SeenOrder[#TelemetryPrompt.SeenOrder + 1] = key
    TelemetryPrompt.Queue[#TelemetryPrompt.Queue + 1] = report
    TelemetryPrompt.ShowNext()
    return true
end

return TelemetryPrompt
