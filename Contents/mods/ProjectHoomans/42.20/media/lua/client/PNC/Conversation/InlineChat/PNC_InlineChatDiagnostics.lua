-- Diagnostics and input-focus callbacks for the inline chat widget.
require "PsychopatzCore/Input/PsychopatzKeybinds"
require "PNC/Commands/PNC_CompanionTargetResolver"
require "PNC/Conversation/InlineChat/PNC_InlineChatDiagnostics_Assert"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InlineChat = PNC.Conversation.InlineChat or {}
PNC.Conversation.InlineChat.Internal = PNC.Conversation.InlineChat.Internal or {}

local InlineChat = PNC.Conversation.InlineChat
local Internal = InlineChat.Internal
local Keybinds = PsychopatzCore.Keybinds
local State = InlineChat.State
local Diagnostics = Internal.Diagnostics or {}
Internal.Diagnostics = Diagnostics
Diagnostics._openRejectAt = Diagnostics._openRejectAt or {}

local function nowMs()
    return (PNC.Core and PNC.Core.Now and PNC.Core.Now())
        or (getTimeInMillis and getTimeInMillis()) or 0
end

local function enabled()
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    return trace and trace.IsEnabled and trace.IsEnabled() == true
end

local function colorDescription(color)
    if not color then return "nil" end
    return table.concat({
        tostring(color.r), tostring(color.g), tostring(color.b), tostring(color.a),
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
    return table.concat({
        "mode=" .. tostring(definition.mode),
        "xywh=" .. tostring(buttonValue(button, "getX", "x")) .. ","
            .. tostring(buttonValue(button, "getY", "y")) .. ","
            .. tostring(buttonValue(button, "getWidth", "width")) .. ","
            .. tostring(buttonValue(button, "getHeight", "height")),
        "enable=" .. tostring(button.enable),
        "variant=" .. tostring(button.psychopatzVariant),
        "bg=" .. colorDescription(button.backgroundColor),
        "border=" .. colorDescription(button.borderColor),
        "image=" .. tostring(button.image),
        "targetIsPart=" .. tostring(button.target == part),
    }, " ")
end

local function describeButtons()
    local part = State.part
    if not part then return "panel=nil modeButtons=0" end
    local descriptions, seen = {}, {}
    local uniqueCount, duplicateCount, targetMismatchCount = 0, 0, 0
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
    local childCount, modeChildCount = 0, 0
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
            .. " ui=" .. tostring(State.part and State.part.inputMode or "nil")
            .. " target=" .. tostring(State.targetID or "nil")
            .. " reason=" .. tostring(reason or "nil")
            .. " " .. describeButtons()
    )
end

function Diagnostics.LogOpenRejected(reason, details)
    local key = tostring(reason or "unknown")
    local now = tonumber(nowMs()) or 0
    local previous = tonumber(Diagnostics._openRejectAt[key]) or -math.huge
    if now - previous < 1000 then return end
    Diagnostics._openRejectAt[key] = now
    if not print then return end
    print("[PNC][InlineChat] inline_open_rejected reason=" .. key .. " " .. tostring(details or ""))
end

function Diagnostics.LogSubmitRejection(view, reason)
    if not print then return end
    local spec = view and view.spec or {}
    local interactive = view and view.isConversationInteractive
        and view:isConversationInteractive() == true or false
    local pbrainz = PNC.PBrainZ
    local pending = pbrainz and pbrainz.GetPending and pbrainz.GetPending() ~= nil or false
    print("[PNC][InlineChat] chat_submit_rejected npc=" .. tostring(spec.npcID or "unknown")
        .. " reason=" .. tostring(reason or "rejected")
        .. " interactive=" .. tostring(interactive)
        .. " pending=" .. tostring(pending))
end

local function isLongPress(binding)
    local longPressType = Keybinds and Keybinds.TYPE_LONG_PRESS or "longpress"
    return type(binding) == "table"
        and tostring(binding.type or "") == tostring(longPressType)
end

local function isEntryFocused(part)
    local entry = part and part.entry or nil
    if not entry then return false end
    if type(entry.isFocused) == "function" then
        local ok, focused = pcall(entry.isFocused, entry)
        if ok then return focused == true end
    end
    return false
end

function Diagnostics.FocusWhenReady()
    if not State.part then return false end
    if State.focusAfterTriggerRelease then
        local binding = State.triggerBinding
        if binding and Keybinds and Keybinds.IsDown and Keybinds.IsDown(binding) then
            return false
        end
        State.focusAfterTriggerRelease = false
        State.triggerBinding = nil
        State.pendingInitialFocus = false
        if State.part.focusInput then
            State.part:focusInput(false)
            return true
        end
        return false
    end
    if State.pendingInitialFocus then
        State.pendingInitialFocus = false
        if not isEntryFocused(State.part) and State.part.focusInput then
            State.part:focusInput(false)
            return true
        end
    end
    return false
end

function Diagnostics.PrepareFocus(binding)
    State.triggerBinding = isLongPress(binding) and binding or nil
    State.focusAfterTriggerRelease = State.triggerBinding ~= nil
    if State.focusAfterTriggerRelease then
        State.pendingInitialFocus = false
        return Diagnostics.FocusWhenReady()
    end
    State.pendingInitialFocus = true
    if State.part and State.part.focusInput then
        State.part:focusInput(binding ~= nil)
        return true
    end
    return false
end

function Diagnostics.OnVisualRefresh(_, part, event)
    if not enabled() or part ~= State.part then return end
    Diagnostics.LogMode("visual_refresh_" .. tostring(event or "unknown"), State.mode, State.mode, nil)
    Diagnostics.AssertModeState(event or "visual_refresh")
end

function Diagnostics.OnModeCommitted(_, mode, part)
    if not enabled() or part ~= State.part then return end
    Diagnostics.LogMode("mode_committed", mode, State.mode, nil)
    Diagnostics.AssertModeState("mode_committed")
end

function Diagnostics.OnNativeControlState(_, part, event, button)
    if not enabled() or part ~= State.part then return end
    Diagnostics.LogMode(
        "native_" .. tostring(event or "unknown"),
        State.mode,
        State.mode,
        "button=" .. tostring(button and button.internal or "unknown")
    )
end

InlineChat.FocusInputWhenReady = Diagnostics.FocusWhenReady

return Diagnostics
