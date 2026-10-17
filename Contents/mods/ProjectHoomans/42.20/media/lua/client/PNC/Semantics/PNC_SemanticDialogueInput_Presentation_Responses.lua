-- Build deterministic semantic reply payloads before queue delivery.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal
local ResponsePlan = require
    "PNC/Semantics/PNC_SemanticDialogueResponsePlan"

local ResponseAdapter = {}

local function semanticTranslationKey(response)
    local templateID = tostring(response and response.templateID or "")
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
    local keys = {
        ["semantic.identity.exchange"] =
            "UI_PNC_Conversation_Semantic_IdentityExchange",
        ["semantic.identity.exchange.unavailable"] =
            "UI_PNC_Conversation_Semantic_IdentityExchangeUnavailable",
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
        ["semantic.flow.greeting.opening.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpening",
        ["semantic.flow.greeting.followup.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingFollowupFriendly",
        ["semantic.flow.greeting.followup.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingFollowup",
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
    if type(firstArg) == "table" then firstArg = nil end
    local ok, value = pcall(translation.TrFormat, key, fallback, firstArg)
    if ok and value ~= nil and tostring(value) ~= "" then
        return tostring(value), key
    end
    return fallback, key
end

local function localizedResponse(response)
    local fallback = tostring(response and response.fallback or "")
    local key = semanticTranslationKey(response)
    if response and type(response.plan) == "table"
        and ResponsePlan and type(ResponsePlan.Render) == "function"
    then
        local rendered = ResponsePlan.Render(
            response.plan,
            localizedSegment,
            1
        )
        if rendered ~= nil and tostring(rendered) ~= "" then
            return tostring(rendered), key
        end
    end
    return localizedSegment(
        response and response.templateID,
        fallback,
        response and response.args
    )
end

function ResponseAdapter.Payload(decision)
    local response = decision and decision.response or {}
    local fallback = tostring(response.fallback or "")
    local text, translationKey = localizedResponse(response)
    return {
        key = response.templateID,
        domain = "pnc.system.shared.categories",
        -- Keep the authored English fallback on the live payload as well as
        -- in the keyed field. Text.Resolve still gives a registered
        -- translation precedence, but a missing/late registration cannot
        -- leak an internal semantic template ID into the UI.
        text = text ~= "" and text or nil,
        fallback = fallback,
        args = response.args,
        translationKey = translationKey,
        plan = response.plan,
    }
end

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
    return ResponseAdapter.Payload({ response = response })
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

return ResponseAdapter
