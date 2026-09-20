-- Build deterministic semantic reply payloads before queue delivery.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

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
    }
    return keys[templateID]
end

local function localizedResponse(response)
    local fallback = tostring(response and response.fallback or "")
    local key = semanticTranslationKey(response)
    local translation = PNC.Translation
    if not key or not translation
        or type(translation.TrFormat) ~= "function"
    then
        return fallback, key
    end
    local args = type(response.args) == "table" and response.args or {}
    local firstArg = args.npcName or args.target or args.object
    if type(firstArg) == "table" then firstArg = nil end
    local ok, value = pcall(translation.TrFormat, key, fallback, firstArg)
    if ok and value ~= nil and tostring(value) ~= "" then
        return tostring(value), key
    end
    return fallback, key
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
    }
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
