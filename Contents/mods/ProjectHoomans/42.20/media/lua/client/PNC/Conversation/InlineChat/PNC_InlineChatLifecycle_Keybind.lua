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

function Lifecycle.Register()
    if Keybinds and Keybinds.RegisterPress then
        local binding = Keybinds.RegisterPress({
            id = "ProjectHoomans.PBrainZChat",
            label = "UI_PNC_PBrainZ_TalkKey",
            tooltip = "UI_PNC_PBrainZ_TalkTooltip",
            defaultKey = getKeyCode and (tonumber(getKeyCode("V")) or 47) or 47,
            isEnabled = function()
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
            onTrigger = InlineChat.Open,
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
