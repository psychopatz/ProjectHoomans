-- Conversation-owned inline (headless) chat adapter facade.
--
-- Core owns the reusable input widget and ConvoEngine owns semantic input/reply
-- processing. This module provides the compact overhead surface on the same
-- conversation/semantic pipeline used by the full conversation UI.
require "PsychopatzCore/Input/PsychopatzKeybinds"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"
require "PNC/Commands/PNC_CompanionTargetResolver"
require "PNC/Conversation/InlineChat/PNC_InlineChatConfig"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InlineChat = PNC.Conversation.InlineChat or {}
PNC.Conversation.InlineChat.Internal = PNC.Conversation.InlineChat.Internal or {}

local Conversation = PNC.Conversation
local InlineChat = Conversation.InlineChat
local Internal = InlineChat.Internal
local Config = Internal.Config
local Text = PsychopatzCore.Conversation.Text
local LLMInput = PsychopatzConversationLLMInput

InlineChat.State = InlineChat.State or {}

local function semanticInput()
    pcall(require, "PNC/ConvoEngine/RuntimeFacade")
    local engine = PNC.ConvoEngine
    local input = engine and engine.DialogueInput or nil
    if input and type(input.Submit) == "function" then return input end
    return nil
end

local function label(key, fallback)
    return Text.Resolve({ key = key, fallback = fallback }, fallback)
end

local function stateFor(view)
    local input = semanticInput()
    if input and type(input.GetState) == "function" then
        return input.GetState(view)
    end
    local pbrainz = PNC.PBrainZ
    local status, enabled, visible = "", false, true
    if not view or not view.session then
        status = label("UI_PsychopatzConversation_LLM_StatusOpen", "OPEN A CONVERSATION")
    elseif view.session.llmPending
        or view.session.semanticDialoguePending
        or (pbrainz and pbrainz.GetPending and pbrainz.GetPending())
    then
        status = label("UI_PsychopatzConversation_LLM_StatusWaiting", "WAITING FOR NPC RESPONSE...")
    elseif type(view.isConversationInteractive) ~= "function"
        or not view:isConversationInteractive()
    then
        status = label("UI_PsychopatzConversation_LLM_StatusSpeaking", "NPC IS SPEAKING...")
    else
        enabled = true
    end
    return {
        visible = visible,
        enabled = enabled,
        statusText = status,
        sendKey = "UI_PsychopatzConversation_LLM_Send",
    }
end

local function submitSemanticFirst(view, value, part)
    local input = semanticInput()
    if input and type(input.Submit) == "function" then
        return input.Submit(view, value, part)
    end
    return false, "semantic_input_unavailable"
end

function InlineChat.CreateInputPart(bounds, options)
    options = options or {}
    options.partID = options.partID or "llmInput"
    options.minimumWidth = options.minimumWidth or 280
    options.minimumHeight = options.minimumHeight or 82
    options.title = options.title or {
        key = "UI_PsychopatzConversation_Panel_LLMInput",
        fallback = "TYPE TO TALK",
    }
    options.submit = options.submit or submitSemanticFirst
    options.getState = options.getState or stateFor
    options.resolveText = options.resolveText or label
    options.maxInputLength = options.maxInputLength or Config.MAX_INPUT_LENGTH
    options.submitOnEnter = options.submitOnEnter ~= false
    options.tooltipKey = options.tooltipKey
        or "UI_PsychopatzConversation_LLM_InputTooltip"
    options.sendKey = options.sendKey or "UI_PsychopatzConversation_LLM_Send"
    options.sendTitle = options.sendTitle or "UI_PsychopatzConversation_LLM_Send"
    return LLMInput:new(bounds.x, bounds.y, bounds.width, bounds.height, options)
end

function InlineChat.IsActive()
    return InlineChat.State and InlineChat.State.part ~= nil
end

InlineChat.GetState = stateFor
InlineChat.ResolveText = label
Conversation.CreateInlineInput = InlineChat.CreateInputPart

require "PNC/Conversation/InlineChat/PNC_InlineChatDiagnostics"
require "PNC/Conversation/InlineChat/PNC_InlineChatTargets"
require "PNC/Conversation/InlineChat/PNC_InlineChatHosts"
require "PNC/Conversation/InlineChat/PNC_InlineChatLifecycle"

local Lifecycle = Internal.Lifecycle
Lifecycle.Register()

return InlineChat
