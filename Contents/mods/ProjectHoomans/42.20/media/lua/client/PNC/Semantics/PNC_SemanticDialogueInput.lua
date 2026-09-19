-- Hybrid conversation input. Lua handles deterministic utterances first;
-- only the policy's explicit fallback route may call PBrainZ.
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"
require "PsychopatzCore/Semantics/PsychopatzSemanticDialogueRouter"
require "PNC/Semantics/PNC_SemanticDiagnostics"
-- The semantic input is a client entry point as well as a shared-composition
-- consumer. Load the Hoomans vocabulary here so a partial composition cannot
-- silently fall through to the generic LLM wait path.
require "PNC/Semantics/PNC_SemanticCatalog"
require "PNC/Semantics/PNC_SemanticConsumptionCatalog"
require "PNC/Semantics/PNC_SemanticDialoguePolicy"
require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
require "PNC/Semantics/PNC_SemanticCommandAdapter"
require "PNC/Semantics/PNC_SemanticTaskAdapter"
require "PNC/Semantics/PNC_SemanticInventoryQueryAdapter"

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Policy = PNC.Semantics.DialoguePolicy
local Text = PsychopatzCore.Conversation.Text
local ResponseCatalog = PNC.Semantics.ResponseCatalog
local LocalResponse = PNC.Semantics.LocalResponse
local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

if LocalResponse and type(LocalResponse.RegisterTextFallbacks) == "function" then
    LocalResponse.RegisterTextFallbacks()
end
if Policy and type(Policy.RegisterTextFallbacks) == "function" then
    Policy.RegisterTextFallbacks()
end
if ResponseCatalog and type(ResponseCatalog.RegisterTextFallbacks) == "function" then
    -- History may contain semantic keys written before keyed fallbacks were
    -- persisted. Register the current catalog before a full-screen session
    -- loads that history so those old rows remain readable as well.
    ResponseCatalog.RegisterTextFallbacks()
end

Input.VERSION = 2
Input.MAX_INPUT_LENGTH = 4000
Input.Internal = Input.Internal or {}

require "PNC/Semantics/PNC_SemanticDialogueInput_Context"
require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation"
require "PNC/Semantics/PNC_SemanticDialogueInput_Actions"
require "PNC/Semantics/PNC_SemanticDialogueInput_GiftPresentation"
require "PNC/Semantics/PNC_SemanticDialogueInput_Gifts"
require "PNC/Semantics/PNC_SemanticDialogueInput_Inventory"
require "PNC/Semantics/PNC_SemanticDialogueInput_Tasks"
require "PNC/Semantics/PNC_SemanticDialogueInput_Trace"
require "PNC/Semantics/PNC_SemanticDialogueInput_ProviderFallback"
require "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle"

local Internal = Input.Internal

function Input.Submit(view, value, part)
    local group = view and view.groupConversation
    if group and type(group.Submit) == "function" then
        return group:Submit(value, part)
    end
    return Internal.SubmitSingle(view, value, part)
end

function Input.GetState(view)
    if not view or not view.session then
        -- The full-screen view constructs extension parts before it creates
        -- its Session. Keep the field mounted during that short lifecycle
        -- gap; hiding it here makes the widget stay invisible because native
        -- child updates may be skipped while the part is hidden.
        return { visible = view ~= nil, enabled = false, statusText = "" }
    end
    if view.session.llmPending or view.session.semanticDialoguePending then
        return {
            visible = true,
            enabled = false,
            statusText = "",
        }
    end
    return {
        visible = true,
        enabled = Internal.Interactive(view),
        statusText = "",
        sendKey = "llm.send",
    }
end

function Input.ResolveText(key, fallback)
    return Text.Resolve({
        key = key,
        domain = "pnc.system.shared.categories",
        fallback = fallback,
    }, fallback)
end

function Input.CreatePart(bounds, options)
    options = options or {}
    options.partID = options.partID or "semanticInput"
    options.minimumWidth = options.minimumWidth or 280
    options.minimumHeight = options.minimumHeight or 82
    options.submit = options.submit or Input.Submit
    options.getState = options.getState or Input.GetState
    options.resolveText = options.resolveText or Input.ResolveText
    options.maxInputLength = options.maxInputLength or Input.MAX_INPUT_LENGTH
    options.submitOnEnter = options.submitOnEnter ~= false
    options.tooltipKey = options.tooltipKey or "llm.input_tooltip"
    options.sendKey = options.sendKey or "llm.send"
    options.sendTitle = options.sendTitle or "SEND"
    return PsychopatzConversationLLMInput:new(
        bounds.x, bounds.y, bounds.width, bounds.height, options
    )
end

return Input
