-- Hybrid conversation input. Lua handles deterministic utterances first;
-- only the policy's explicit fallback route may call HoomansLLM.
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"
require "PsychopatzCore/Semantics/PsychopatzSemanticDialogueRouter"
-- The semantic input is a client entry point as well as a shared-composition
-- consumer. Load the Hoomans vocabulary here so a partial composition cannot
-- silently fall through to the generic LLM wait path.
require "PNC/Semantics/PNC_SemanticCatalog"
require "PNC/Semantics/PNC_SemanticDialoguePolicy"
require "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
require "PNC/Semantics/PNC_SemanticCommandAdapter"
require "PNC/Semantics/PNC_SemanticTaskAdapter"
require "PNC/Semantics/PNC_SemanticInventoryQueryAdapter"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Semantics = PNC.Semantics or {}

local Conversation = PNC.Conversation
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

local function traceTurn(view, value, result, event, extra)
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    if not trace or type(trace.IsEnabled) ~= "function"
        or trace.IsEnabled() ~= true
        or type(trace.Record) ~= "function"
    then
        return false
    end
    local ir = result and result.ir or {}
    local decision = result and result.decision or {}
    local provenance = ir.provenance or {}
    local data = {
        npcID = view and view.spec and view.spec.npcID,
        rawText = string.sub(tostring(value or ""), 1, 256),
        normalizedText = string.sub(
            tostring(ir.normalizedText or ""), 1, 256
        ),
        route = decision.route,
        branch = decision.branch,
        confidence = ir.confidence,
        intent = ir.intent,
        speechAct = ir.speechAct,
        action = ir.action,
        subject = ir.subject,
        target = ir.target,
        inventoryQuery = ir.inventoryQuery,
        provider = provenance.provider,
        parser = provenance.parser,
        pattern = provenance.pattern,
        diagnostics = ir.diagnostics,
    }
    for key, item in pairs(type(extra) == "table" and extra or {}) do
        data[key] = item
    end
    return trace.Record({
        source = "ProjectHoomans.Semantics",
        event = event or "semantic_input",
        data = data,
    })
end

require "PNC/Semantics/PNC_SemanticDialogueInput_Context"
require "PNC/Semantics/PNC_SemanticDialogueInput_Presentation"
require "PNC/Semantics/PNC_SemanticDialogueInput_Actions"
require "PNC/Semantics/PNC_SemanticDialogueInput_Inventory"

local Internal = Input.Internal

function Input.Submit(view, value, part)
    if not view or not view.session then
        return false, "conversation_unavailable"
    end
    -- Keep the submitting host available to asynchronous local projections.
    -- Full-screen conversations are discoverable through Core's singleton,
    -- while compact/headless conversations are deliberately not global.  The
    -- reference is runtime-only and is never serialized or sent over the
    -- network.
    Input.ActiveView = view
    if not Internal.Interactive(view) then return false, "conversation_busy" end
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return false, "empty_message" end
    value = string.sub(value, 1, Input.MAX_INPUT_LENGTH)

    local router, routerReason = Internal.RouterFor(view)
    if not router then return false, routerReason end
    local context = Internal.ShallowContext(view)
    local options = {
        timestamp = Internal.Now(),
    }
    local preview
    if type(router.Preview) == "function" then
        preview = router:Preview(value, context, options)
    else
        preview = router:Process(value, context, options)
    end
    if preview.accepted ~= true then
        return false, preview.reason or "semantic_input_rejected"
    end

    if Internal.RequestCognitionForIR then
        Internal.RequestCognitionForIR(view, preview.ir)
    end

    local decision = preview.decision or {}
    if decision.route == "llm_fallback" then
        traceTurn(view, value, preview, "semantic_input_llm_fallback", {
            providerAvailable = context.llmAvailable == true,
        })
        local integration = PNC.HoomansLLM
        local llmAvailable = context.llmAvailable == true
        if llmAvailable
            and integration and type(integration.Submit) == "function"
        then
            view.session.semanticDialoguePending = {
                rawText = value,
                normalizedText = preview.ir and preview.ir.normalizedText,
                preview = preview,
                context = context,
                part = part,
            }
            local accepted, reason = integration.Submit(view, value, part)
            if accepted == true then
                view.lastSemanticDialogueResult = preview
                return true
            end
            view.session.semanticDialoguePending = nil
            decision.diagnostics = decision.diagnostics or {}
            decision.diagnostics.llmSubmitReason = reason
        elseif llmAvailable then
            decision.diagnostics = decision.diagnostics or {}
            decision.diagnostics.llmSubmitReason = "llm_submit_unavailable"
        end
        -- Provider absence, stale worker state, and request rejection are all
        -- normal optional-LLM deployment states. Keep the conversation alive
        -- with a deterministic clarification instead of showing a fake wait.
        decision.route = "deterministic"
        decision.branch = "ASK_CLARIFICATION"
        decision.response = Policy.ResponseTemplates.ASK_CLARIFICATION
        context.llmEnabled = false
        context.llmAvailable = false
        options.llmEnabled = false
    end

    local result = preview
    if type(router.Preview) == "function" then
        result = router:ProcessIR(preview.ir, context, options)
    end
    view.lastSemanticDialogueResult = result

    traceTurn(view, value, result, "semantic_input_local", {
        providerAvailable = context.llmAvailable == true,
        providerUsed = false,
    })

    local inputMessage = Internal.AppendPlayerInput(view, value, result)
    if not inputMessage then return false, "input_presentation_failed" end
    local actionResult = Internal.DispatchAction(view, result, value)
    Internal.QueueDeterministicResponse(view, value, result, actionResult)
    return true
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

Conversation.CreateSemanticDialogueInput = Input.CreatePart

return Input
