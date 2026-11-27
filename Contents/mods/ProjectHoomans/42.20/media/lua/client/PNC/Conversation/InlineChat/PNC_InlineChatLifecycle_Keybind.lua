-- Keybind and event hook registration for inline chat lifecycle.
require "PsychopatzCore/Input/PsychopatzKeybinds"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InlineChat = PNC.Conversation.InlineChat or {}
PNC.Conversation.InlineChat.Internal = PNC.Conversation.InlineChat.Internal or {}

local InlineChat = PNC.Conversation.InlineChat
local Internal = InlineChat.Internal
local Keybinds = PsychopatzCore.Keybinds
local State = InlineChat.State
local Diagnostics = Internal.Diagnostics
local Targets = Internal.Targets
local Lifecycle = Internal.Lifecycle or {}
Internal.Lifecycle = Lifecycle

local function logBlockedKeybind(reason, details)
    if not Keybinds.IsPressed or not Keybinds.IsPressed("ProjectHoomans.PBrainZChat") then return end
    if Diagnostics and Diagnostics.LogOpenRejected then
        Diagnostics.LogOpenRejected(reason, details)
    end
end

local function closeOnEscape(key)
    if State.part and Keyboard and key == Keyboard.KEY_ESCAPE then
        InlineChat.Close("escape")
    end
end

local KEYBIND_ID = "ProjectHoomans.PBrainZChat"

local function isToggleKeyDown()
    if not Keybinds or not Keybinds.IsDown then return false end
    return Keybinds.IsDown(KEYBIND_ID) == true
end

local function eatToggleKey()
    if not GameKeyboard or not GameKeyboard.eatKeyPress then return end
    local code = Keybinds and Keybinds.GetKeyCode
        and tonumber(Keybinds.GetKeyCode(KEYBIND_ID)) or 0
    if code and code > 0 then
        pcall(GameKeyboard.eatKeyPress, code)
    end
end

local function closeViaToggleKeybind()
    State.toggleKeyHeld = true
    State.suppressReopenUntilRelease = true
    eatToggleKey()
    InlineChat.Close("toggle_keybind")
    return true
end

function Lifecycle.PollToggleClose()
    local keyDown = isToggleKeyDown()
    if not State.part then
        if not keyDown then
            State.toggleKeyHeld = false
            State.suppressReopenUntilRelease = false
        end
        return false
    end
    if keyDown then
        if State.toggleKeyHeld ~= true then
            return closeViaToggleKeybind()
        end
        return false
    end
    State.toggleKeyHeld = false
    return false
end

function Lifecycle.OnKeybindTrigger(binding)
    if State.suppressReopenUntilRelease then
        if isToggleKeyDown() then return false end
        State.suppressReopenUntilRelease = false
    end
    if State.part then
        return closeViaToggleKeybind()
    end
    return InlineChat.Open(binding)
end

local function resolveSlashKeyCode()
    local code = Keyboard and tonumber(Keyboard.KEY_SLASH) or nil
    if code and code > 0 then return code end
    code = getKeyCode and tonumber(getKeyCode("SLASH")) or nil
    if code and code > 0 then return code end
    return 53
end

function Lifecycle.Register()
    if Keybinds and Keybinds.RegisterPress then
        local binding = Keybinds.RegisterPress({
            id = KEYBIND_ID,
            label = "UI_PNC_PBrainZ_TalkKey",
            tooltip = "UI_PNC_PBrainZ_TalkTooltip",
            defaultKey = resolveSlashKeyCode(),
            deprecatedDefaultKey = (Keyboard and tonumber(Keyboard.KEY_V)) or 47,
            isEnabled = function()
                if State.suppressReopenUntilRelease then
                    if isToggleKeyDown() then return false end
                    State.suppressReopenUntilRelease = false
                end
                if State.part then
                    return true
                end
                local pbrainz = PNC.PBrainZ
                local pending = pbrainz and pbrainz.GetPending and pbrainz.GetPending() or nil
                if pending then
                    logBlockedKeybind("request_pending", "npc=" .. tostring(pending.npcID or "unknown"))
                    return false
                end
                local view = Targets.CurrentView()
                if view then
                    logBlockedKeybind("conversation_active",
                        "npc=" .. tostring(view.spec and view.spec.npcID or "unknown"))
                    return false
                end
                return true
            end,
            onTrigger = Lifecycle.OnKeybindTrigger,
        })
        if PNC.Core and PNC.Core.LogInfo then
            PNC.Core.LogInfo("inline_keybind_registered id=ProjectHoomans.PBrainZChat registered="
                .. tostring(binding ~= nil and binding ~= false)
                .. " key=" .. tostring(Keybinds.GetKeyCode and Keybinds.GetKeyCode(binding) or "unknown"))
        end
    end
    if Events and Events.OnTick and not InlineChat._tickHookRegistered then
        Events.OnTick.Add(InlineChat.Update)
        InlineChat._tickHookRegistered = true
    end
    if Events and Events.OnKeyPressed and not InlineChat._escapeHookRegistered then
        Events.OnKeyPressed.Add(closeOnEscape)
        InlineChat._escapeHookRegistered = true
    end
end

return Lifecycle
