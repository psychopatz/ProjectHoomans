-- Inline chat adapter facade.
--
-- Core owns the reusable input widget. HoomansLLM owns only the integration
-- policy and delegates diagnostics, targeting, hosts, and lifecycle work to
-- focused providers.
require "PsychopatzCore/Input/PsychopatzKeybinds"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"
require "PNC/Commands/PNC_CompanionTargetResolver"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_InlineChatConfig"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_State"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Runtime"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local State = Internal.State
local Config = Internal.InlineChatConfig
local Conversation = PNC.Conversation
local Text = PsychopatzCore.Conversation.Text
local LLMInput = PsychopatzConversationLLMInput

local function semanticInput()
    local semantics = PNC.Semantics
    local input = semantics and semantics.DialogueInput or nil
    if input and type(input.Submit) == "function" then return input end
    pcall(require, "PNC/Semantics/PNC_SemanticDialogueInput")
    semantics = PNC.Semantics
    input = semantics and semantics.DialogueInput or nil
    return input and type(input.Submit) == "function" and input or nil
end

local function label(key, fallback)
    return Text.Resolve({
        key = key,
        domain = "pnc.system.shared.categories",
        fallback = fallback,
    }, fallback)
end

local function stateFor(view)
    local status = ""
    local enabled = false
    local visible = true
    if not view or not view.session then
        status = label("llm.status.open", "OPEN A CONVERSATION")
    elseif view.session.llmPending
        or view.session.semanticDialoguePending
        or Integration.GetPending and Integration.GetPending()
    then
        status = label("llm.status.waiting", "WAITING FOR NPC RESPONSE...")
    elseif type(view.isConversationInteractive) ~= "function"
        or not view:isConversationInteractive()
    then
        status = label("llm.status.speaking", "NPC IS SPEAKING...")
    else
        enabled = true
    end
    return {
        visible = visible,
        enabled = enabled,
        statusText = status,
        sendKey = "llm.send",
    }
end

local function submitHybrid(view, value, part)
    local input = semanticInput()
    if input and type(input.Submit) == "function" then
        return input.Submit(view, value, part)
    end
    -- The legacy submit path always assumes an LLM request. Falling through
    -- to it would let a partial load-order failure turn a local utterance
    -- into the old waiting placeholder. Keep the hybrid entry point fail
    -- closed; the semantic module owns the only valid remote fallback route.
    return false, "semantic_input_unavailable"
end

function Integration.CreateInputPart(bounds, options)
    options = options or {}
    options.partID = options.partID or "llmInput"
    options.minimumWidth = options.minimumWidth or 280
    options.minimumHeight = options.minimumHeight or 82
    options.title = options.title or {
        key = "panel.llm_input",
        domain = "pnc.system.shared.categories",
        fallback = "TYPE TO TALK",
    }
    options.submit = options.submit or submitHybrid
    options.getState = options.getState or stateFor
    options.resolveText = options.resolveText or label
    options.maxInputLength = options.maxInputLength
        or State.MAX_INPUT_LENGTH
    options.submitOnEnter = options.submitOnEnter ~= false
    options.tooltipKey = options.tooltipKey or "llm.input_tooltip"
    options.sendKey = options.sendKey or "llm.send"
    options.sendTitle = options.sendTitle or "SEND"
    return LLMInput:new(
        bounds.x, bounds.y, bounds.width, bounds.height, options
    )
end

Integration.GetInlineState = stateFor
Integration.ResolveInlineText = label
ISPNCHoomansLLMInput = LLMInput
Conversation.CreateHoomansLLMInput = Integration.CreateInputPart
Integration.Inline = Integration.Inline or {}

require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_InlineChatDiagnostics"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_InlineChatTargets"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_InlineChatHosts"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_InlineChatLifecycle"

local Lifecycle = Internal.InlineChatLifecycle
Lifecycle.Register()

return LLMInput
