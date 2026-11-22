-- Button and recipient highlight consistency assertions for inline chat diagnostics.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InlineChat = PNC.Conversation.InlineChat or {}
PNC.Conversation.InlineChat.Internal = PNC.Conversation.InlineChat.Internal or {}

local InlineChat = PNC.Conversation.InlineChat
local Internal = InlineChat.Internal
local Config = Internal.Config
local State = InlineChat.State
local Diagnostics = Internal.Diagnostics or {}
Internal.Diagnostics = Diagnostics

local function enabled()
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    return trace and trace.IsEnabled and trace.IsEnabled() == true
end

local function colorsEqual(left, right)
    if not left or not right then return false end
    return math.abs((tonumber(left.r) or 0) - (tonumber(right.r) or 0)) < 0.0001
        and math.abs((tonumber(left.g) or 0) - (tonumber(right.g) or 0)) < 0.0001
        and math.abs((tonumber(left.b) or 0) - (tonumber(right.b) or 0)) < 0.0001
        and math.abs((tonumber(left.a) or 0) - (tonumber(right.a) or 0)) < 0.0001
end

local function nativeButtonSelected(button)
    local theme = PsychopatzCore and PsychopatzCore.UI and PsychopatzCore.UI.Theme
    if theme and theme.Color then
        return colorsEqual(button.backgroundColor, theme.Color("accentDark"))
            and colorsEqual(button.borderColor, theme.Color("accent"))
    end
    return button.psychopatzVariant == "selected"
end

function Diagnostics.AssertModeState(event)
    if not enabled() then return true end
    local part = State.part
    local targets = PNC.CompanionTargetResolver
    if not part or not targets then return true end
    local committed = targets.NormalizeMode(State.mode or Config.MODE_NEAREST)
    local uiMode = part.inputMode and targets.NormalizeMode(part.inputMode) or nil
    local selectedMode, selectedCount, modeButtonCount = nil, 0, 0
    local buttonsOK, allModeButtonsEnabled = true, true
    for _, definition in ipairs(part.modeButtons or {}) do
        local button = definition and definition.button
        if button then
            modeButtonCount = modeButtonCount + 1
            local isEnabled = button.enable ~= false
            if not isEnabled then allModeButtonsEnabled = false end
            if isEnabled and nativeButtonSelected(button) then
                selectedCount = selectedCount + 1
                selectedMode = definition.mode
            end
            if button.psychopatzVariant ~= (definition.mode == committed and "selected" or "quiet") then
                buttonsOK = false
            end
        end
    end
    local nativeOK = not allModeButtonsEnabled
        or (modeButtonCount == 2 and selectedCount == 1 and selectedMode == committed)
    local expected = {}
    for _, entry in ipairs(State.entries or {}) do
        local id = tostring(entry and entry.id or "")
        if id ~= "" then expected[id] = true end
    end
    local outlined, outlinedCount, recipientsOK = State.highlightedZombies or {}, 0, true
    for id in pairs(expected) do
        if outlined[id] == nil then recipientsOK = false end
    end
    for id in pairs(outlined) do
        outlinedCount = outlinedCount + 1
        if not expected[id] then recipientsOK = false end
    end
    if uiMode ~= committed or not nativeOK or not buttonsOK or not recipientsOK then
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn(
                "inline_mode_assertion_failed event=" .. tostring(event)
                    .. " committed=" .. tostring(committed)
                    .. " ui=" .. tostring(uiMode)
                    .. " selected=" .. tostring(selectedMode)
                    .. " selectedCount=" .. tostring(selectedCount)
                    .. " nativeSelectionCheck=" .. tostring(allModeButtonsEnabled and "enabled" or "disabled")
                    .. " outlined=" .. tostring(outlinedCount)
                    .. " expectedOutlined=" .. tostring(#(State.entries or {}))
                    .. " buttonsOK=" .. tostring(buttonsOK)
                    .. " recipientsOK=" .. tostring(recipientsOK)
            )
        end
        return false
    end
    return true
end

InlineChat.AssertModeState = Diagnostics.AssertModeState

return Diagnostics
