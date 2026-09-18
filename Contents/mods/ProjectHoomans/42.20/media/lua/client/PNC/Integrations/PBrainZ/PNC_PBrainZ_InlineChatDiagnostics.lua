-- Diagnostics and input-focus callbacks for the inline chat widget.
require "PsychopatzCore/Input/PsychopatzKeybinds"
require "PNC/Commands/PNC_CompanionTargetResolver"

PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}

local Integration = PNC.PBrainZ
local Internal = Integration.Internal
local Config = Internal.InlineChatConfig
local Keybinds = PsychopatzCore.Keybinds
local Targets = PNC.CompanionTargetResolver
local Inline = Integration.Inline
local Diagnostics = Internal.InlineChatDiagnostics or {}
Internal.InlineChatDiagnostics = Diagnostics

local function enabled()
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    return trace and trace.IsEnabled and trace.IsEnabled() == true
end

local function colorDescription(color)
    if not color then return "nil" end
    return table.concat({
        tostring(color.r), tostring(color.g), tostring(color.b),
        tostring(color.a),
    }, ",")
end

local function buttonValue(button, getter, field)
    if not button then return nil end
    if getter and button[getter] then return button[getter](button) end
    return button[field]
end

local function buttonDescription(definition, part)
    local button = definition and definition.button
    if not button then
        return "mode=" .. tostring(definition and definition.mode) .. ":nil"
    end
    local x = buttonValue(button, "getX", "x")
    local y = buttonValue(button, "getY", "y")
    local width = buttonValue(button, "getWidth", "width")
    local height = buttonValue(button, "getHeight", "height")
    return table.concat({
        "mode=" .. tostring(definition.mode),
        "xywh=" .. tostring(x) .. "," .. tostring(y) .. ","
            .. tostring(width) .. "," .. tostring(height),
        "enable=" .. tostring(button.enable),
        "variant=" .. tostring(button.psychopatzVariant),
        "bg=" .. colorDescription(button.backgroundColor),
        "bgHover=" .. colorDescription(button.backgroundColorMouseOver),
        "border=" .. colorDescription(button.borderColor),
        "text=" .. colorDescription(button.textColor),
        "bgEnabled=" .. colorDescription(button.backgroundColorEnabled),
        "borderEnabled=" .. colorDescription(button.borderColorEnabled),
        "image=" .. tostring(button.image),
        "tooltip=" .. tostring(button.tooltip),
        "targetIsPart=" .. tostring(button.target == part),
    }, " ")
end

local function describeButtons()
    local part = Inline.part
    if not part then return "panel=nil modeButtons=0" end
    local descriptions = {}
    local seen = {}
    local uniqueCount = 0
    local duplicateCount = 0
    local targetMismatchCount = 0
    for _, definition in ipairs(part.modeButtons or {}) do
        local button = definition and definition.button
        if button and seen[button] then duplicateCount = duplicateCount + 1 end
        if button and not seen[button] then
            seen[button] = true
            uniqueCount = uniqueCount + 1
        end
        if button and button.target ~= nil and button.target ~= part then
            targetMismatchCount = targetMismatchCount + 1
        end
        descriptions[#descriptions + 1] = buttonDescription(definition, part)
    end
    local children = part.getChildren and part:getChildren() or part.children
    local childCount = 0
    local modeChildCount = 0
    if type(children) == "table" then
        for _, child in ipairs(children) do
            childCount = childCount + 1
            if seen[child] then modeChildCount = modeChildCount + 1 end
        end
    end
    return "panel=" .. tostring(part)
        .. " modeButtons=" .. tostring(#(part.modeButtons or {}))
        .. " uniqueButtons=" .. tostring(uniqueCount)
        .. " duplicateButtons=" .. tostring(duplicateCount)
        .. " targetMismatches=" .. tostring(targetMismatchCount)
        .. " children=" .. tostring(childCount)
        .. " modeChildren=" .. tostring(modeChildCount)
        .. " buttons=[" .. table.concat(descriptions, " || ") .. "]"
end

function Diagnostics.LogMode(event, requested, committed, reason)
    if not enabled() or not PNC.Core or not PNC.Core.LogInfo then return end
    PNC.Core.LogInfo(
        "inline_mode event=" .. tostring(event or "unknown")
            .. " requested=" .. tostring(requested or "nil")
            .. " committed=" .. tostring(committed or "nil")
            .. " ui=" .. tostring(Inline.part and Inline.part.inputMode or "nil")
            .. " target=" .. tostring(Inline.targetID or "nil")
            .. " reason=" .. tostring(reason or "nil")
            .. " " .. describeButtons()
    )
end

function Diagnostics.LogSubmitRejection(view, reason)
    if not print then return end
    local spec = view and view.spec or {}
    local interactive = view and view.isConversationInteractive
        and view:isConversationInteractive() == true or false
    local pending = Integration.GetPending
        and Integration.GetPending() ~= nil or false
    print("[PNC][LLM] chat_submit_rejected "
        .. "npc=" .. tostring(spec.npcID or "unknown")
        .. " reason=" .. tostring(reason or "rejected")
        .. " interactive=" .. tostring(interactive)
        .. " pending=" .. tostring(pending))
end

local function colorsEqual(left, right)
    if not left or not right then return false end
    return math.abs((tonumber(left.r) or 0) - (tonumber(right.r) or 0)) < 0.0001
        and math.abs((tonumber(left.g) or 0) - (tonumber(right.g) or 0)) < 0.0001
        and math.abs((tonumber(left.b) or 0) - (tonumber(right.b) or 0)) < 0.0001
        and math.abs((tonumber(left.a) or 0) - (tonumber(right.a) or 0)) < 0.0001
end

local function nativeButtonSelected(button)
    local theme = PsychopatzCore and PsychopatzCore.UI
        and PsychopatzCore.UI.Theme
    if theme and theme.Color then
        return colorsEqual(button.backgroundColor, theme.Color("accentDark"))
            and colorsEqual(button.borderColor, theme.Color("accent"))
    end
    return button.psychopatzVariant == "selected"
end

function Diagnostics.AssertModeState(event)
    if not enabled() then return true end
    local part = Inline.part
    if not part or not Targets then return true end
    local committed = Targets.NormalizeMode(
        Inline.mode or Config.MODE_NEAREST
    )
    local uiMode = part.inputMode and Targets.NormalizeMode(part.inputMode)
        or nil
    local selectedMode
    local selectedCount = 0
    local buttonsOK = true
    local modeButtonCount = 0
    local allModeButtonsEnabled = true
    for _, definition in ipairs(part.modeButtons or {}) do
        local button = definition and definition.button
        if button then
            modeButtonCount = modeButtonCount + 1
            local isEnabled = button.enable ~= false
            if not isEnabled then allModeButtonsEnabled = false end
            local isSelected = isEnabled and nativeButtonSelected(button) or false
            if isSelected then
                selectedCount = selectedCount + 1
                selectedMode = definition.mode
            end
            local expectedSelected = definition.mode == committed
            if button.psychopatzVariant
                ~= (expectedSelected and "selected" or "quiet")
            then
                buttonsOK = false
            end
        end
    end
    local nativeSelectionOK = not allModeButtonsEnabled
        or (modeButtonCount == 2
            and selectedCount == 1
            and selectedMode == committed)
    local expectedRecipients = {}
    for _, entry in ipairs(Inline.entries or {}) do
        local id = tostring(entry and entry.id or "")
        if id ~= "" then expectedRecipients[id] = true end
    end
    local outlinedRecipients = Inline.highlightedZombies or {}
    local outlinedCount = 0
    local recipientsOK = true
    for id in pairs(expectedRecipients) do
        if outlinedRecipients[id] == nil then recipientsOK = false end
    end
    for id, _ in pairs(outlinedRecipients) do
        outlinedCount = outlinedCount + 1
        if not expectedRecipients[id] then recipientsOK = false end
    end
    if uiMode ~= committed
        or not nativeSelectionOK
        or not buttonsOK
        or not recipientsOK
    then
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn(
                "inline_mode_assertion_failed event=" .. tostring(event)
                    .. " committed=" .. tostring(committed)
                    .. " ui=" .. tostring(uiMode)
                    .. " selected=" .. tostring(selectedMode)
                    .. " selectedCount=" .. tostring(selectedCount)
                    .. " nativeSelectionCheck=" .. tostring(
                        allModeButtonsEnabled and "enabled" or "disabled")
                    .. " outlined=" .. tostring(outlinedCount)
                    .. " expectedOutlined=" .. tostring(#(Inline.entries or {}))
                    .. " buttonsOK=" .. tostring(buttonsOK)
                    .. " recipientsOK=" .. tostring(recipientsOK)
            )
        end
        return false
    end
    return true
end

local function isLongPress(binding)
    local longPressType = Keybinds and Keybinds.TYPE_LONG_PRESS or "longpress"
    return type(binding) == "table"
        and tostring(binding.type or "") == tostring(longPressType)
end

function Diagnostics.FocusWhenReady()
    if not Inline.part or not Inline.focusAfterTriggerRelease then
        return false
    end
    local binding = Inline.triggerBinding
    if binding and Keybinds and Keybinds.IsDown and Keybinds.IsDown(binding) then
        return false
    end
    Inline.focusAfterTriggerRelease = false
    Inline.triggerBinding = nil
    if Inline.part.focusInput then
        Inline.part:focusInput()
        return true
    end
    return false
end

function Diagnostics.PrepareFocus(binding)
    Inline.triggerBinding = isLongPress(binding) and binding or nil
    Inline.focusAfterTriggerRelease = Inline.triggerBinding ~= nil
    if Inline.focusAfterTriggerRelease then return Diagnostics.FocusWhenReady() end
    if Inline.part and Inline.part.focusInput then
        Inline.part:focusInput()
        return true
    end
    return false
end

function Diagnostics.OnVisualRefresh(_, part, event)
    if not enabled() or part ~= Inline.part then return end
    Diagnostics.LogMode(
        "visual_refresh_" .. tostring(event or "unknown"),
        Inline.mode, Inline.mode, nil
    )
    Diagnostics.AssertModeState(event or "visual_refresh")
end

function Diagnostics.OnModeCommitted(_, mode, part)
    if not enabled() or part ~= Inline.part then return end
    Diagnostics.LogMode("mode_committed", mode, Inline.mode, nil)
    Diagnostics.AssertModeState("mode_committed")
end

function Diagnostics.OnNativeControlState(_, part, event, button)
    if not enabled() or part ~= Inline.part then return end
    Diagnostics.LogMode(
        "native_" .. tostring(event or "unknown"),
        Inline.mode,
        Inline.mode,
        "button=" .. tostring(button and button.internal or "unknown")
    )
end

Integration.AssertInlineModeState = Diagnostics.AssertModeState
Integration.FocusInlineInputWhenReady = Diagnostics.FocusWhenReady

return Diagnostics
