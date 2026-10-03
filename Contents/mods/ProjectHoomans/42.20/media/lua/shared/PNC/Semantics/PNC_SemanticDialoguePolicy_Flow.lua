-- Semantic dialogue policy public decision/process flow.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local IR = Semantic.IR
local Policy = PNC.Semantics.DialoguePolicy
local Internal = Policy.Internal or {}
Policy.Internal = Internal
local thresholds = Internal.Thresholds
local llmEnabled = Internal.LLMEnabled
local decision = Internal.Decision
local applyLocalResponse = Internal.ApplyLocalResponse
local resolveIntentBranch = Internal.ResolveIntentBranch
local giftConsentFor = Internal.GiftConsentFor
local classifyGiftOffer = Internal.ClassifyGiftOffer
local fuzzyActionNeedsConfirmation =
    Internal.FuzzyActionNeedsConfirmation
local unresolvedItemRequest = Internal.UnresolvedItemRequest
local unresolvedOffer = Internal.UnresolvedOffer
local isInventoryQuery = Internal.IsInventoryQuery
local isLocalFactQuestion = Internal.IsLocalFactQuestion
local unresolvedWorldTargetRequest = Internal.UnresolvedWorldTargetRequest
local isIdentityClaim = Internal.IsIdentityClaim

function Policy.Decide(ir, state, context, options)
    options = type(options) == "table" and options or {}
    local limits = thresholds(options)
    local hasLLM = llmEnabled(context, options)

    local valid, validationReason = IR.Validate(ir)
    if valid ~= true then
        local result = decision(
            { confidence = 0 },
            hasLLM and "llm_fallback" or "deterministic",
            hasLLM and "AMBIGUOUS_INPUT" or "ASK_CLARIFICATION",
            validationReason or "invalid_ir",
            options
        )
        result.diagnostics.llmEligible = hasLLM
        return applyLocalResponse(result, ir, state, context)
    end

    local diagnostics = ir.diagnostics or {}
    local confidence = tonumber(ir.confidence) or 0
    local giftOffer = classifyGiftOffer(ir)
    if diagnostics.noMatch == true or confidence < limits.medium then
        local result = decision(
            ir,
            hasLLM and "llm_fallback" or "deterministic",
            hasLLM and "AMBIGUOUS_INPUT" or "ASK_CLARIFICATION",
            diagnostics.noMatch == true and "no_match" or "low_confidence",
            options
        )
        result.diagnostics.llmEligible = hasLLM
        return applyLocalResponse(result, ir, state, context)
    end

    -- A resolvable reference is required before a semantic action can be
    -- handed to a downstream command adapter. The policy itself never
    -- resolves world entities; it chooses clarification or fallback.
    if (diagnostics.unresolvedEntity == true
            and not unresolvedItemRequest(ir)
            and not unresolvedOffer(ir)
            and not isInventoryQuery(ir)
            and not isLocalFactQuestion(ir)
            and not unresolvedWorldTargetRequest(ir)
            and not isIdentityClaim(ir))
        or (confidence < limits.high and not giftOffer)
    then
        local result = decision(
            ir,
            "deterministic",
            "ASK_CLARIFICATION",
            diagnostics.unresolvedEntity == true
                and "unresolved_reference" or "medium_confidence",
            options
        )
        result.diagnostics.llmEligible = hasLLM
        return applyLocalResponse(result, ir, state, context)
    end

    if fuzzyActionNeedsConfirmation(ir, options) then
        local result = decision(
            ir,
            "deterministic",
            "ASK_CLARIFICATION",
            "fuzzy_action_requires_confirmation",
            options
        )
        result.diagnostics.llmEligible = hasLLM
        result.diagnostics.fuzzyActionRequiresConfirmation = true
        return applyLocalResponse(result, ir, state, context)
    end

    local branch, reason = resolveIntentBranch(ir, state, context, giftOffer)
    local giftConsent = giftConsentFor(ir, context)
    if giftConsent then
        if giftConsent.status == "granted" then
            branch = "GIFT_CONSENT_GRANTED"
            reason = "gift_offer_confirmed"
        elseif giftConsent.status == "declined" then
            branch = "GIFT_CONSENT_DECLINED"
            reason = "gift_offer_declined"
        else
            branch = "GIFT_CONSENT_AMBIGUOUS"
            reason = "gift_offer_recipient_ambiguous"
        end
    end

    local result = decision(ir, "deterministic", branch, reason, options)
    result.giftConsent = giftConsent
    result.diagnostics.llmEligible = hasLLM
    if state then
        result.diagnostics.stateSequence = state.sequence
        result.diagnostics.currentTopic = state.currentTopic
    end
    return applyLocalResponse(result, ir, state, context)
end

function Policy.Process(text, state, context, options)
    local ir = Semantic.Parser.Parse(text, options)
    if state then
        local recorded, recordReason = state:Record(ir, options)
        if not recorded then
            return ir, nil, recordReason
        end
    end
    local result = Policy.Decide(ir, state, context, options)
    if state and type(state.CompletePending) == "function" then
        -- Preserve pending context through decision/response composition, then
        -- retire an obligation answered by this turn.
        state:CompletePending(ir)
    end
    return ir, result
end


return Policy
