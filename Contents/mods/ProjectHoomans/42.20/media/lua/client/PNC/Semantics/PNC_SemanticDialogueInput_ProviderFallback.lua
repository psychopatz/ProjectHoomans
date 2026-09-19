-- Optional provider handoff with deterministic clarification on failure.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal
local Policy = PNC.Semantics.DialoguePolicy
local Trace = PNC.Semantics.DialogueInputTrace or {}

local function traceTurn(view, value, result, eventName, extra)
    if type(Trace.RecordTurn) ~= "function" then return false end
    return Trace.RecordTurn(view, value, result, eventName, extra)
end

function Internal.SubmitProviderFallback(
    view, value, part, preview, decision, context, options)
    traceTurn(view, value, preview, "semantic_input_llm_fallback", {
        providerAvailable = context.llmAvailable == true,
    })
    local integration = PNC.PBrainZ
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
    -- Provider absence, stale worker state, and request rejection are normal
    -- optional-integration states. Continue with deterministic clarification.
    decision.route = "deterministic"
    decision.branch = "ASK_CLARIFICATION"
    decision.response = Policy.ResponseTemplates.ASK_CLARIFICATION
    context.llmEnabled = false
    context.llmAvailable = false
    options.llmEnabled = false
    return false
end

return Internal
