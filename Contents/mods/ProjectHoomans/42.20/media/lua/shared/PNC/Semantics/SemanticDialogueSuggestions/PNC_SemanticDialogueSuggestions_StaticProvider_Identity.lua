-- Identity-exchange candidate projection and context checks.

local function identityKnown(context)
    context = type(context) == "table" and context or {}
    if context.identityState == "known"
        or context.identityKnown == true
    then
        return true
    end
    local actor = type(context.actorConversationContext) == "table"
        and context.actorConversationContext or {}
    local roles = type(actor.roles) == "table" and actor.roles or {}
    return roles.companion == true and roles.owned == true
        and roles.authorityEligible == true
end

local function pendingIdentity(context)
    local state = context and context.semanticContextState
    return context and context.pendingIdentityExchange
        or state and state.pendingIdentityExchange
        or context and context.semanticDialogueContext
        and context.semanticDialogueContext.pendingIdentityExchange
end

local function identityChoiceCandidate(
    Provider, id, labelKey, labelFallback, utteranceKey, utteranceFallback,
    choice, frame
)
    return {
        id = id,
        topic = "identity",
        groupID = "topic:identity",
        providerID = Provider.id,
        rank = choice,
        semanticOwner = "projecthoomans.semantic.identity",
        eligibility = {
            status = "allowed",
            allowed = true,
            reason = "identity_exchange_pending",
        },
        source = {
            kind = Provider.sourceKind,
            providerID = Provider.id,
            reason = "identity_exchange_pending",
        },
        frame = frame,
        display = {
            labelKey = labelKey,
            labelFallback = labelFallback,
            utteranceKey = utteranceKey,
            utteranceFallback = utteranceFallback,
        },
        visibility = "player",
    }
end

local function identityChoiceCandidates(context, Provider, IdentityAlias)
    local source = {
        characterUUID = context.characterUUID
            or context.playerIdentitySeed,
        gender = context.playerGender,
        playerName = context.playerName,
        saveSeed = context.saveSeed,
    }
    local alias = "Alex Reed"
    if IdentityAlias and type(IdentityAlias.Generate) == "function" then
        local ok, generated = pcall(IdentityAlias.Generate, source)
        if ok and tostring(generated or "") ~= "" then
            alias = tostring(generated)
        end
    end
    local function frameFor(
        id, intent, choice, identityClaimMode, claimedName, utterance,
        identityResponseStyle
    )
        local socialContext = {}
        if intent == "INFORM" then socialContext.identityClaim = true end
        return {
            kind = "semantic_click_frame",
            candidateID = id,
            topic = "identity",
            pattern = "pnc.identity.choice." .. choice,
            intent = intent,
            speechAct = intent,
            subject = "IDENTITY",
            slots = intent == "INFORM" and {
                identityClaim = {
                    mode = identityClaimMode,
                    name = claimedName,
                },
            } or {},
            socialContext = socialContext,
            extensions = {
                route = "semantic_provider",
                providerID = Provider.id,
                identityChoice = choice,
                identityClaimMode = identityClaimMode,
                identityResponseStyle = identityResponseStyle,
            },
            textKey = intent == "REFUSE" and
                "UI_PNC_Conversation_Suggestion_Identity_Rude_Utterance"
                or (choice == "real_name" and
                    "UI_PNC_Conversation_Suggestion_Identity_Real_Utterance"
                    or "UI_PNC_Conversation_Suggestion_Identity_Lie_Utterance"),
            textFallback = utterance,
            labelKey = intent == "REFUSE" and
                "UI_PNC_Conversation_Suggestion_Identity_Rude_Label"
                or (choice == "real_name" and
                    "UI_PNC_Conversation_Suggestion_Identity_Real_Label"
                    or "UI_PNC_Conversation_Suggestion_Identity_Lie_Label"),
        }
    end
    local realFrame = frameFor(
        "identity.choice.real_name", "INFORM", "real_name", "canonical",
        source.playerName, "My real name.", nil
    )
    local rudeFrame = frameFor(
        "identity.choice.refuse_name", "REFUSE", "refuse_name", nil, nil,
        "That's none of your business.", "rude"
    )
    local lieFrame = frameFor(
        "identity.choice.lie_name", "INFORM", "lie_name", "generated",
        alias, "I'll go by " .. tostring(alias) .. ".", nil
    )
    return {
        identityChoiceCandidate(
            Provider,
            "identity.choice.real_name",
            "UI_PNC_Conversation_Suggestion_Identity_Real_Label",
            "Say your real name",
            "UI_PNC_Conversation_Suggestion_Identity_Real_Utterance",
            "My real name.", 10, realFrame
        ),
        identityChoiceCandidate(
            Provider,
            "identity.choice.refuse_name",
            "UI_PNC_Conversation_Suggestion_Identity_Rude_Label",
            "Don't tell your name",
            "UI_PNC_Conversation_Suggestion_Identity_Rude_Utterance",
            "That's none of your business.", 20, rudeFrame
        ),
        identityChoiceCandidate(
            Provider,
            "identity.choice.lie_name",
            "UI_PNC_Conversation_Suggestion_Identity_Lie_Label",
            "Lie about your name",
            "UI_PNC_Conversation_Suggestion_Identity_Lie_Utterance",
            "I'll go by " .. tostring(alias) .. ".", 30, lieFrame
        ),
    }
end

return {
    identityKnown = identityKnown,
    pendingIdentity = pendingIdentity,
    identityChoiceCandidates = identityChoiceCandidates,
}
