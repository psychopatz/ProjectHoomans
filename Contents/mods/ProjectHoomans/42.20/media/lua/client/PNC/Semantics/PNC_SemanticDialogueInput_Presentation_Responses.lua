-- Build deterministic semantic reply payloads before queue delivery.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal
local ResponsePlan = require
    "PNC/Semantics/PNC_SemanticDialogueResponsePlan"
local SpeechRealization = require
    "PNC/Semantics/PNC_SpeechRealization"

local ResponseAdapter = {}

local BACKSTORY_KINDS = {
    former_job = "UI_PNC_Conversation_Semantic_QuestionBackstoryFormerJob",
    hometown = "UI_PNC_Conversation_Semantic_QuestionBackstoryHometown",
    education = "UI_PNC_Conversation_Semantic_QuestionBackstoryEducation",
    hobby = "UI_PNC_Conversation_Semantic_QuestionBackstoryHobby",
    family_background = "UI_PNC_Conversation_Semantic_QuestionBackstoryFamily",
    fear = "UI_PNC_Conversation_Semantic_QuestionBackstoryFear",
    tragedy = "UI_PNC_Conversation_Semantic_QuestionBackstoryTragedy",
}

local function semanticTranslationKey(response)
    local templateID = tostring(response and response.templateID or "")
    if string.sub(templateID, 1, 7) == "UI_PNC_" then
        return templateID
    end
    if templateID == "semantic.question.identity" then
        local fallback = tostring(response and response.fallback or "")
        if string.find(string.lower(fallback), "liars", 1, true) then
            return "UI_PNC_Conversation_Semantic_QuestionIdentityWary"
        end
        if string.sub(fallback, 1, 4) == "I'm " then
            return "UI_PNC_Conversation_Semantic_QuestionIdentityKnown"
        end
        return "UI_PNC_Conversation_Semantic_QuestionIdentity"
    end
    if templateID == "semantic.question.backstory.known" then
        local args = response and response.args
        return BACKSTORY_KINDS[args and args.kind]
            or "UI_PNC_Conversation_Semantic_QuestionBackstoryKnown"
    end
    if templateID == "semantic.question.backstory.suspected" then
        return "UI_PNC_Conversation_Semantic_QuestionBackstorySuspected"
    end
    if templateID == "semantic.question.backstory.ambiguous" then
        return "UI_PNC_Conversation_Semantic_QuestionBackstoryAmbiguous"
    end
    if templateID == "semantic.question.backstory.refusal" then
        return "UI_PNC_Conversation_Semantic_QuestionBackstoryRefusal"
    end
    local keys = {
        ["semantic.identity.exchange"] =
            "UI_PNC_Conversation_Semantic_IdentityExchange",
        ["semantic.identity.exchange.unavailable"] =
            "UI_PNC_Conversation_Semantic_IdentityExchangeUnavailable",
        ["semantic.action.follow.unavailable"] =
            "UI_PNC_Conversation_Semantic_ActionFollowUnavailable",
        ["semantic.action.stay.unavailable"] =
            "UI_PNC_Conversation_Semantic_ActionStayUnavailable",
        ["semantic.action.stop.unavailable"] =
            "UI_PNC_Conversation_Semantic_ActionStopUnavailable",
        ["semantic.social.interaction.unavailable"] =
            "UI_PNC_Conversation_Semantic_SocialInteractionUnavailable",
        ["semantic.social.interaction.rejected"] =
            "UI_PNC_Conversation_Semantic_SocialInteractionRejected",
        ["semantic.question.identity.stranger_alt_1"] =
            "UI_PNC_Conversation_Semantic_QuestionIdentityStrangerAlt1",
        ["semantic.question.identity.stranger_alt_2"] =
            "UI_PNC_Conversation_Semantic_QuestionIdentityStrangerAlt2",
        ["semantic.question.identity.wary_alt_1"] =
            "UI_PNC_Conversation_Semantic_QuestionIdentityWaryAlt1",
        ["semantic.question.identity.wary_alt_2"] =
            "UI_PNC_Conversation_Semantic_QuestionIdentityWaryAlt2",
        ["semantic.social.self_reflection.friendly"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionFriendly",
        ["semantic.social.self_reflection.trusted"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionTrusted",
        ["semantic.social.self_reflection.withdrawn"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionWithdrawn",
        ["semantic.social.self_reflection.stressed"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionStressed",
        ["semantic.social.self_reflection.default"] =
            "UI_PNC_Conversation_Semantic_SelfReflectionDefault",
        ["semantic.identity.evasion.untrustworthy"] =
            "UI_PNC_Conversation_Semantic_IdentityEvasionUntrustworthy",
        ["semantic.identity.evasion.friendly"] =
            "UI_PNC_Conversation_Semantic_IdentityEvasionFriendly",
        ["semantic.identity.evasion.withdrawn"] =
            "UI_PNC_Conversation_Semantic_IdentityEvasionWithdrawn",
        ["semantic.identity.evasion.default"] =
            "UI_PNC_Conversation_Semantic_IdentityEvasionDefault",
        ["semantic.flow.greeting.opening.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningFriendly",
        ["semantic.flow.greeting.opening.rain"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningRain",
        ["semantic.flow.greeting.opening.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpening",
        ["semantic.flow.greeting.opening.question.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestionFriendly",
        ["semantic.flow.greeting.opening.question.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestion",
        ["semantic.flow.greeting.followup.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingFollowupFriendly",
        ["semantic.flow.greeting.followup.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingFollowup",
        ["semantic.flow.weather.raining.default"] =
            "UI_PNC_Conversation_Semantic_FlowWeatherRaining",
        ["semantic.flow.weather.clear.default"] =
            "UI_PNC_Conversation_Semantic_FlowWeatherClear",
        ["semantic.flow.weather.unknown.default"] =
            "UI_PNC_Conversation_Semantic_FlowWeatherUnknown",
        ["semantic.social.compliment.default"] =
            "UI_PNC_Conversation_Semantic_ComplimentDefault",
        ["semantic.social.compliment.alternate"] =
            "UI_PNC_Conversation_Semantic_ComplimentAlternate",
        ["semantic.social.compliment.friendly"] =
            "UI_PNC_Conversation_Semantic_ComplimentFriendly",
        ["semantic.social.compliment.trusted"] =
            "UI_PNC_Conversation_Semantic_ComplimentTrusted",
        ["semantic.social.compliment.withdrawn"] =
            "UI_PNC_Conversation_Semantic_ComplimentWithdrawn",
        ["semantic.question.relationship_status.committed"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusCommitted",
        ["semantic.question.relationship_status.uncertain"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusUncertain",
        ["semantic.question.relationship_status.uncertain_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusUncertainAlt",
        ["semantic.question.relationship_status.withdrawn"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusWithdrawn",
        ["semantic.question.relationship_status.after_compliment.committed"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentCommitted",
        ["semantic.question.relationship_status.after_compliment.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterCompliment",
        ["semantic.question.relationship_status.after_compliment.unknown_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentAlt",
        ["semantic.question.relationship_status.after_compliment.withdrawn"] =
            "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentWithdrawn",
        ["semantic.question.relationship_status.acknowledged.default"] =
            "UI_PNC_Conversation_Semantic_RelationshipStatusAcknowledged",
        ["semantic.question.relationship_status.acknowledged.alternate"] =
            "UI_PNC_Conversation_Semantic_RelationshipStatusAcknowledgedAlt",
        ["semantic.question.relationship_status.acknowledged.withdrawn"] =
            "UI_PNC_Conversation_Semantic_RelationshipStatusAcknowledgedWithdrawn",
        ["semantic.question.wellbeing.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingUnknown",
        ["semantic.question.wellbeing.panic"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingPanic",
        ["semantic.question.wellbeing.stress"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingStress",
        ["semantic.question.wellbeing.thirst"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingThirst",
        ["semantic.question.wellbeing.thirst_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingThirstAlt",
        ["semantic.question.wellbeing.hunger"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingHunger",
        ["semantic.question.wellbeing.hunger_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingHungerAlt",
        ["semantic.question.wellbeing.fatigue"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFatigue",
        ["semantic.question.wellbeing.fatigue_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFatigueAlt",
        ["semantic.question.wellbeing.injured"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingInjured",
        ["semantic.question.wellbeing.grounded.friendly.fact"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedFriendlyFact",
        ["semantic.question.wellbeing.grounded.friendly.tone"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedFriendlyTone",
        ["semantic.question.wellbeing.grounded.withdrawn.fact"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedWithdrawnFact",
        ["semantic.question.wellbeing.grounded.withdrawn.tone"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingGroundedWithdrawnTone",
        ["semantic.question.wellbeing.default"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDefault",
        ["semantic.question.wellbeing.dataset.hanging_in"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetHangingIn",
        ["semantic.question.wellbeing.dataset.all_things_considered"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetAllThingsConsidered",
        ["semantic.question.wellbeing.dataset.getting_by"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetGettingBy",
        ["semantic.question.wellbeing.dataset.hungry"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetHungry",
        ["semantic.question.wellbeing.dataset.thirsty"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetThirsty",
        ["semantic.question.wellbeing.dataset.tired"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDatasetTired",
        ["semantic.question.wellbeing.follow_up.panic"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpPanic",
        ["semantic.question.wellbeing.follow_up.stress"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpStress",
        ["semantic.question.wellbeing.follow_up.thirst"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpThirst",
        ["semantic.question.wellbeing.follow_up.hunger"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpHunger",
        ["semantic.question.wellbeing.follow_up.fatigue"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpFatigue",
        ["semantic.question.wellbeing.follow_up.injured"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpInjured",
        ["semantic.question.wellbeing.follow_up.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpUnknown",
        ["semantic.question.wellbeing.follow_up.default"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFollowUpDefault",
        ["semantic.question.medical_bite.positive"] =
            "UI_PNC_Conversation_Semantic_QuestionMedicalBitePositive",
        ["semantic.question.medical_bite.negative"] =
            "UI_PNC_Conversation_Semantic_QuestionMedicalBiteNegative",
        ["semantic.question.medical_bite.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionMedicalBiteUnknown",
        ["semantic.question.residence.known"] =
            "UI_PNC_Conversation_Semantic_QuestionResidenceKnown",
        ["semantic.question.residence.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionResidenceUnknown",
        ["semantic.question.health_state.injured"] =
            "UI_PNC_Conversation_Semantic_QuestionHealthStateInjured",
        ["semantic.question.health_state.healthy"] =
            "UI_PNC_Conversation_Semantic_QuestionHealthStateHealthy",
        ["semantic.question.health_state.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionHealthStateUnknown",
        ["semantic.question.knowledge.known"] =
            "UI_PNC_Conversation_Semantic_QuestionKnowledgeKnown",
        ["semantic.question.knowledge.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionKnowledgeUnknown",
        ["semantic.conversation.acknowledged.default"] =
            "UI_PNC_Conversation_Semantic_ConversationAcknowledged",
        ["semantic.conversation.acknowledged.friendly"] =
            "UI_PNC_Conversation_Semantic_ConversationAcknowledgedFriendly",
        ["semantic.conversation.acknowledged.withdrawn"] =
            "UI_PNC_Conversation_Semantic_ConversationAcknowledgedWithdrawn",
        ["semantic.conversation.continuation.gossip_memory"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationGossipMemory",
        ["semantic.conversation.continuation.gossip_unknown"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationGossipUnknown",
        ["semantic.conversation.continuation.residence"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationResidence",
        ["semantic.conversation.continuation.medical"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationMedical",
        ["semantic.conversation.continuation.medical_known"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationMedicalKnown",
        ["semantic.conversation.continuation.medical_unknown"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationMedicalUnknown",
        ["semantic.conversation.continuation.knowledge"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationKnowledge",
        ["semantic.conversation.continuation.default"] =
            "UI_PNC_Conversation_Semantic_ConversationContinuationDefault",
        ["semantic.conversation.context_reference.unknown"] =

            "UI_PNC_Conversation_Semantic_ContextReferenceUnknown",

        ["semantic.conversation.context_reference.cause_unknown"] =

            "UI_PNC_Conversation_Semantic_ContextReferenceCauseUnknown",

        ["semantic.conversation.context_reference.location_safety_unknown"] =

            "UI_PNC_Conversation_Semantic_ContextReferenceLocationSafetyUnknown",

        ["semantic.conversation.context_reference.description_unknown"] =

            "UI_PNC_Conversation_Semantic_ContextReferenceDescriptionUnknown",

        ["semantic.conversation.context_reference.medical_unknown"] =

            "UI_PNC_Conversation_Semantic_ContextReferenceMedicalUnknown",

        ["semantic.question.needs.offer.hunger"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsOfferHunger",
        ["semantic.question.needs.offer.thirst"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsOfferThirst",
        ["semantic.question.needs.offer.fatigue"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsOfferFatigue",
        ["semantic.question.needs.offer.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsOfferUnknown",
        ["semantic.question.needs.quantity.hunger"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsQuantityHunger",
        ["semantic.question.needs.quantity.thirst"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsQuantityThirst",
        ["semantic.question.needs.quantity.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsQuantityUnknown",
        ["semantic.question.needs.proposal.hunger"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsProposalHunger",
        ["semantic.question.needs.proposal.thirst"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsProposalThirst",
        ["semantic.question.needs.proposal.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionNeedsProposalUnknown",
        ["semantic.social.apology.friendly"] =
            "UI_PNC_Conversation_Semantic_ApologyFriendly",
        ["semantic.social.apology.trusted"] =
            "UI_PNC_Conversation_Semantic_ApologyTrusted",
        ["semantic.social.apology.stressed"] =
            "UI_PNC_Conversation_Semantic_ApologyStressed",
        ["semantic.social.apology.withdrawn"] =
            "UI_PNC_Conversation_Semantic_ApologyWithdrawn",
        ["semantic.social.apology.default"] =
            "UI_PNC_Conversation_Semantic_ApologyDefault",
        ["semantic.social.threat_stressed"] =
            "UI_PNC_Conversation_Semantic_ThreatStressed",
        ["semantic.social.threat_withdrawn"] =
            "UI_PNC_Conversation_Semantic_ThreatWithdrawn",
        ["semantic.social.threat_trusted"] =
            "UI_PNC_Conversation_Semantic_ThreatTrusted",
        ["semantic.social.offer_stressed"] =
            "UI_PNC_Conversation_Semantic_OfferStressed",
        ["semantic.social.offer_friendly"] =
            "UI_PNC_Conversation_Semantic_OfferFriendly",
        ["semantic.social.offer_trusted"] =
            "UI_PNC_Conversation_Semantic_OfferTrusted",
        ["semantic.social.offer_withdrawn"] =
            "UI_PNC_Conversation_Semantic_OfferWithdrawn",
        ["semantic.social.dispute_stressed"] =
            "UI_PNC_Conversation_Semantic_DisputeStressed",
        ["semantic.social.dispute_friendly"] =
            "UI_PNC_Conversation_Semantic_DisputeFriendly",
        ["semantic.social.dispute_trusted"] =
            "UI_PNC_Conversation_Semantic_DisputeTrusted",
        ["semantic.social.dispute_withdrawn"] =
            "UI_PNC_Conversation_Semantic_DisputeWithdrawn",
        ["semantic.social.refuse_request"] =
            "UI_PNC_Conversation_Semantic_RefuseRequest",
    }
    return keys[templateID]
end

local function localizedSegment(templateID, fallback, args)
    local response = {
        templateID = templateID,
        fallback = fallback,
        args = args,
    }
    fallback = tostring(fallback or "")
    local key = semanticTranslationKey(response)
    local translation = PNC.Translation
    if not key or not translation
        or type(translation.TrFormat) ~= "function"
    then
        return fallback, key
    end
    args = type(args) == "table" and args or {}
    local firstArg = args.npcName or args.target or args.object
        or args.location or args.topic or args.content or args.value
    if type(firstArg) == "table" then firstArg = nil end
    local ok, value = pcall(translation.TrFormat, key, fallback, firstArg)
    if ok and value ~= nil and tostring(value) ~= "" then
        return tostring(value), key
    end
    return fallback, key
end

local function fallbackSegment(templateID, fallback)
    return fallback, nil
end

local function payloadForPlanTurn(response, rendered, fallbackRendered)
    local firstSegment = rendered.segments[1] or {}
    local key = firstSegment.templateID or response.templateID
    if rendered.index > 1 and firstSegment.templateID then
        key = firstSegment.templateID
    end
    local translationKey = rendered.translationKeys[1]
    return {
        key = key,
        domain = "pnc.system.shared.categories",
        -- Keep the authored English fallback on every live payload. Text
        -- resolution still gives a registered translation precedence, but a
        -- missing/late registration cannot leak a template ID into the UI.
        text = rendered.text ~= "" and rendered.text or nil,
        fallback = fallbackRendered.text,
        args = firstSegment.args or response.args,
        translationKey = translationKey,
        translationKeys = rendered.translationKeys,
        plan = response.plan,
        planTurn = rendered.index,
        planTurnID = rendered.id,
        planContinuation = rendered.continuation,
        topic = response.topic,
        referenceTopic = response.referenceTopic,
        referenceSubject = response.referenceSubject,
        segments = rendered.segments,
        speechStyleContext = response.speechStyleContext,
        realization = response.realization,
        realizationFamily = response.realizationFamily,
        realizationVariant = response.realizationVariant,
        realizationFallbackReason = response.realizationFallbackReason,
        renderTemplateID = response.renderTemplateID,
    }
end

local function payloadsForResponse(response)
    response = type(response) == "table" and response or {}
    if type(response.plan) == "table"
        and ResponsePlan
        and type(ResponsePlan.RenderDetailed) == "function"
        and type(ResponsePlan.Validate) == "function"
    then
        local valid = ResponsePlan.Validate(response.plan)
        if valid then
            local payloads = {}
            local index
            for index = 1, #response.plan.turns do
                local rendered = ResponsePlan.RenderDetailed(
                    response.plan,
                    localizedSegment,
                    index
                )
                local fallbackRendered = ResponsePlan.RenderDetailed(
                    response.plan,
                    fallbackSegment,
                    index
                )
                if rendered and fallbackRendered
                    and rendered.text ~= ""
                then
                    payloads[#payloads + 1] = payloadForPlanTurn(
                        response,
                        rendered,
                        fallbackRendered
                    )
                end
            end
            if #payloads > 0 then return payloads end
        end
    end

    local fallback = tostring(response.fallback or "")
    local renderTemplateID = response.renderTemplateID or response.templateID
    local text, translationKey = localizedSegment(
        renderTemplateID,
        fallback,
        response.args
    )
    return {
        {
            key = response.templateID,
            domain = "pnc.system.shared.categories",
            text = text ~= "" and text or nil,
            fallback = fallback,
            args = response.args,
            translationKey = translationKey,
            plan = response.plan,
            planTurn = 1,
            topic = response.topic,
            referenceTopic = response.referenceTopic,
            referenceSubject = response.referenceSubject,
            speechStyleContext = response.speechStyleContext,
            realization = response.realization,
            realizationFamily = response.realizationFamily,
            realizationVariant = response.realizationVariant,
            realizationFallbackReason = response.realizationFallbackReason,
            renderTemplateID = renderTemplateID,
        },
    }
end

function ResponseAdapter.Payloads(decision, context)
    local response = decision and decision.response or {}
    -- Realize only a presentation copy. The decision response and its plan
    -- remain the semantic/action authority for later policy and dispatch.
    response = SpeechRealization.Apply(response, context)
    return payloadsForResponse(response)
end

function ResponseAdapter.Payload(decision, context)
    return ResponseAdapter.Payloads(decision, context)[1]
end

-- Authoritative conversation receipts (knowledge disclosure, identity, and
-- similar server results) use the same typed translation-argument binding as
-- ordinary deterministic turns. Keep the adapter private by default while
-- exposing this narrow production hook to the existing conversation
-- lifecycle receiver.
Internal.ResponsePayload = ResponseAdapter.Payload

function ResponseAdapter.IdentityExchangeUnavailable()
    return ResponseAdapter.Payload({
        response = {
            templateID = "semantic.identity.exchange.unavailable",
            fallback = "I couldn't verify your name just now. Could you tell me again?",
        },
    })
end

function ResponseAdapter.IdentityQuestion(context, state)
    local localResponse = PNC.Semantics
        and PNC.Semantics.LocalResponse or nil
    local response
    if localResponse and type(localResponse.Resolve) == "function" then
        response = localResponse.Resolve(
            { intent = "QUESTION", subject = "IDENTITY" },
            state,
            type(context) == "table" and context or {},
            "QUESTION_RECEIVED"
        )
    end
    if type(response) ~= "table" then
        response = {
            templateID = "semantic.question.identity",
            fallback = "I'll tell you my name once we've established some trust. What's your name?",
        }
    end
    return ResponseAdapter.Payload({ response = response }, context)
end

function ResponseAdapter.CampAcknowledgement(result, actionResult)
    local decision = result and result.decision or {}
    local action = string.upper(tostring(decision.action
        or actionResult and actionResult.action or ""))
    if action ~= "CAMP" or not actionResult
        or actionResult.accepted ~= true
        or type(Internal.CampResponseFor) ~= "function"
    then
        return nil
    end
    local phase = (actionResult.status == "pending"
        or actionResult.reason == "network_queued")
        and "pending" or "admitted"
    local text = Internal.CampResponseFor(
        actionResult,
        decision,
        phase
    )
    if not text then return nil end
    return {
        key = "semantic.camp.requested",
        domain = "pnc.system.shared.categories",
        text = text,
        fallback = text,
    }
end

function ResponseAdapter.ActionRejected(result, actionResult)
    if type(actionResult) ~= "table"
        or actionResult.accepted ~= false
        or actionResult.status == "unmapped"
        or actionResult.status == "skipped"
    then
        return nil
    end
    local action = string.upper(tostring(
        result and result.ir and result.ir.action
        or actionResult.action or ""
    ))
    local speechAct = string.upper(tostring(
        result and result.ir
        and (result.ir.speechAct or result.ir.intent) or ""
    ))
    local socialAct = speechAct == "INSULT"
        or speechAct == "HOSTILE_REMARK"
        or speechAct == "THREATEN"
    if socialAct then
        local reason = tostring(actionResult.reason or "")
        local unavailable = string.find(reason, "unavailable", 1, true)
            or string.find(reason, "transport", 1, true)
            or actionResult.status == "semantic_social_dispatch_unavailable"
        local templateID = unavailable
            and "semantic.social.interaction.unavailable"
            or "semantic.social.interaction.rejected"
        local fallback = unavailable
            and "I heard you, but I couldn't send that social reaction right now."
            or "I heard you, but I couldn't apply that social reaction."
        return ResponseAdapter.Payload({
            response = {
                templateID = templateID,
                fallback = fallback,
                args = {
                    reason = reason,
                    speechAct = speechAct,
                },
            },
        })
    end
    local binding = actionResult.binding
    local bindingPools = type(binding) == "table"
        and binding.responsePools or nil
    local bindingFailed = actionResult.status == "failed"
        or type(actionResult.details) == "table"
        and actionResult.details.status == "failed"
    local bindingOutcome = bindingFailed and "failed" or "rejected"
    local bindingResponse = type(bindingPools) == "table"
        and bindingPools[bindingOutcome] or nil
    if type(bindingResponse) == "table"
        and type(bindingResponse.key) == "string"
        and bindingResponse.key ~= ""
    then
        return ResponseAdapter.Payload({
            response = {
                templateID = bindingResponse.key,
                fallback = bindingResponse.en or bindingResponse.fallback,
                args = {
                    action = action,
                    reason = actionResult.reason,
                },
            },
        })
    end
    -- Task admission failures already flow through ReceiveSemanticTaskResult,
    -- which owns their single authoritative task-result line. Avoid adding a
    -- second generic action-unavailable line for WAIT_AT.
    if action == "WAIT_AT" then return nil end
    local fallback = "I couldn't do that right now."
    if action == "FOLLOW" or tostring(actionResult.commandID) == "follow" then
        fallback = "I can't follow you right now."
    elseif action == "STAY" then
        fallback = "I can't stay right now."
    elseif action == "STOP"
        or tostring(actionResult.commandID) == "stay"
    then
        fallback = "I can't stop right now."
    end
    local templateID = "semantic.action.unavailable"
    if action == "FOLLOW" or tostring(actionResult.commandID) == "follow" then
        templateID = "semantic.action.follow.unavailable"
    elseif action == "STAY" then
        templateID = "semantic.action.stay.unavailable"
    elseif action == "STOP"
        or tostring(actionResult.commandID) == "stay"
    then
        templateID = "semantic.action.stop.unavailable"
    end
    return ResponseAdapter.Payload({
        response = {
            templateID = templateID,
            fallback = fallback,
            args = {
                action = action,
                reason = actionResult.reason,
            },
        },
    })
end

return ResponseAdapter
