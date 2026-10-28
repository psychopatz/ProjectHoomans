-- Semantic dialogue policy public decision/process flow.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Semantic = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local IR = Semantic.IR
local SocialFeatures = require "PNC/Semantics/PNC_SemanticSocialFeatures"
local RiskPolicy = require "PNC/Semantics/PNC_SemanticDialogueRiskPolicy"
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
local isBackstoryContextQuestion = Internal.IsBackstoryContextQuestion
local unresolvedWorldTargetRequest = Internal.UnresolvedWorldTargetRequest
local isIdentityClaim = Internal.IsIdentityClaim
local isEntityIndependentSocialAct =
    Internal.IsEntityIndependentSocialAct
local flowKernel = Internal.FlowKernel
local interactionDirector = Internal.InteractionDirector

function Policy.Decide(ir, state, context, options)
    options = type(options) == "table" and options or {}
    if SocialFeatures and type(SocialFeatures.Annotate) == "function" then
        SocialFeatures.Annotate(ir)
    end
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

    -- A flow preview is meaningful only when the caller supplied the
    -- semantic state that CommitFlow will later update. Standalone policy
    -- decisions remain the pure response path used by callers that do not
    -- own a conversation session.
    local flowPreview = state and flowKernel
        and flowKernel.Preview(ir, state, context, options) or nil
    local function finish(result)
        if flowPreview then
            result.flow = flowPreview
            result.diagnostics.flow = flowPreview.diagnostics
        end
        if state
            and type(context) == "table"
            and context.semanticContextState ~= nil
            and interactionDirector
            and type(interactionDirector.Preview) == "function"
            and result.branch ~= "ASK_CLARIFICATION"
            and result.branch ~= "AMBIGUOUS_INPUT"
        then
            result.director = interactionDirector.Preview(
                ir, state, context, options
            )
            result.interactionPlan = result.director
                and result.director.interactionPlan or nil
            result.diagnostics.director = {
                selectedBeat = result.director.selectedBeat
                    and result.director.selectedBeat.id,
                selectedBehavior = result.director.selectedBehavior
                    and result.director.selectedBehavior.id,
            }
        end
        return applyLocalResponse(result, ir, state, context)
    end

    local diagnostics = ir.diagnostics or {}
    local giftOffer = classifyGiftOffer(ir)
    if diagnostics.noMatch == true then
        local result = decision(
            ir,
            hasLLM and "llm_fallback" or "deterministic",
            hasLLM and "AMBIGUOUS_INPUT" or "ASK_CLARIFICATION",
            "no_match",
            options
        )
        result.diagnostics.llmEligible = hasLLM
        return finish(result)
    end

    local risk = RiskPolicy.Assess(ir, context, options)
    if risk.accepted ~= true then
        local llmEligibleForRisk = hasLLM
            and risk.riskClass ~= "mutating"
            and risk.riskClass ~= "identity_mutation"
            and risk.riskClass ~= "transactional_offer"
        local result = decision(
            ir,
            llmEligibleForRisk and "llm_fallback" or "deterministic",
            llmEligibleForRisk and "AMBIGUOUS_INPUT" or "ASK_CLARIFICATION",
            risk.reason,
            options
        )
        result.diagnostics.llmEligible = llmEligibleForRisk
        result.diagnostics.riskAssessment = risk
        return finish(result)
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
    result.diagnostics.riskAssessment = risk
    if state then
        result.diagnostics.stateSequence = state.sequence
        result.diagnostics.currentTopic = state.currentTopic
    end
    return finish(result)
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
    if type(Policy.CommitFlow) == "function" then
        local committedFlow = Policy.CommitFlow(
            result, ir, state, context, options
        )
        if type(committedFlow) == "table" then
            result.flow = committedFlow
        end
    end
    if state and type(state.CompletePending) == "function" then
        -- Preserve pending context through decision/response composition, then
        -- retire an obligation answered by this turn.
        state:CompletePending(ir)
    end
    return ir, result
end


return Policy
