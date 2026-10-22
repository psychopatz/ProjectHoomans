-- Project Hoomans' static semantic question provider.
--
-- Definitions are declarative content.  Eligibility, localization, and
-- click-time authority remain in the existing suggestion pipeline.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Provider = PNC.Semantics.DialogueStaticChoiceProvider or {}
PNC.Semantics.DialogueStaticChoiceProvider = Provider

Provider.id = "projecthoomans.static_questions"
Provider.sourceKind = "typed_input"
Provider.order = 50

Provider.Definitions = {
    {
        id = "question.wellbeing",
        topic = "wellbeing",
        order = 10,
        patternID = "pnc.question.wellbeing_feeling",
        labelKey = "UI_PNC_Conversation_Suggestion_Wellbeing_Label",
        labelFallback = "How are you feeling?",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Wellbeing_Utterance",
        utteranceFallback = "How are you feeling?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "WELLBEING",
        hubID = "whats_up",
    },
    {
        id = "question.wellbeing_detail",
        topic = "wellbeing",
        order = 20,
        patternID = "pnc.question.wellbeing_follow_up_what_is_wrong",
        labelKey = "UI_PNC_Conversation_Suggestion_WellbeingDetail_Label",
        labelFallback = "Can you tell me more?",
        utteranceKey = "UI_PNC_Conversation_Suggestion_WellbeingDetail_Utterance",
        utteranceFallback = "What's wrong?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "WELLBEING",
        extensions = { dialogueFollowUp = "WELLBEING" },
        slots = { followUp = true },
    },
    {
        id = "question.needs",
        topic = "needs",
        order = 30,
        patternID = "pnc.question.needs_offer_plain",
        labelKey = "UI_PNC_Conversation_Suggestion_Needs_Label",
        labelFallback = "Do you need anything?",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Needs_Utterance",
        utteranceFallback = "Do you need anything?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "NEEDS",
        hubID = "whats_up",
        hubAudience = "owned_companion",
        extensions = {
            topic = "needs",
            dialogueFollowUp = "NEEDS_QUANTITY",
        },
    },
    {
        id = "question.health",
        topic = "medical",
        order = 40,
        patternID = "pnc.question.health.are_you_hurt",
        labelKey = "UI_PNC_Conversation_Suggestion_Health_Label",
        labelFallback = "Are you hurt?",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Health_Utterance",
        utteranceFallback = "Are you hurt?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "NPC_HEALTH_STATE",
        target = "SELF",
        slots = { attribute = "health_state" },
        modifiers = { directed = true },
        socialContext = {
            directed = true,
            personalQuestion = true,
            target = "SELF",
        },
        hubID = "whats_up",
        hubAudience = "owned_companion",
        extensions = { topic = "medical" },
    },
    {
        id = "question.activity",
        topic = "activity",
        order = 60,
        patternID = "pnc.question.activity",
        labelKey = "UI_PNC_Conversation_Suggestion_Activity_Label",
        labelFallback = "Ask what they've been doing",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Activity_Utterance",
        utteranceFallback = "What have you been doing?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "ACTIVITY",
        extensions = { topic = "activity" },
        hubID = "whats_up",
        hubOnly = true,
    },
    {
        id = "question.gossip",
        topic = "gossip",
        order = 70,
        patternID = "pnc.social.gossip_event",
        labelKey = "UI_PNC_Conversation_Suggestion_Gossip_Label",
        labelFallback = "Heard any gossip?",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Gossip_Utterance",
        utteranceFallback = "Any gossip?",
        intent = "GOSSIP",
        speechAct = "GOSSIP",
        subject = "GOSSIP",
        extensions = { topic = "gossip" },
        hubID = "whats_up",
        hubOnly = true,
        hubRequiresSafeGossip = true,
    },
    {
        id = "question.identity",
        topic = "identity",
        order = 50,
        patternID = "pnc.question.identity",
        labelKey = "UI_PNC_Conversation_Suggestion_Identity_Label",
        labelFallback = "Who are you?",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Identity_Utterance",
        utteranceFallback = "Who are you?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "IDENTITY",
    },
    {
        id = "question.time",
        topic = "time",
        order = 60,
        patternID = "pnc.question.time",
        labelKey = "UI_PNC_Conversation_Suggestion_Time_Label",
        labelFallback = "Ask about the time",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Time_Utterance",
        utteranceFallback = "What time is it?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "TIME",
        extensions = { topic = "time" },
    },
    {
        id = "question.date",
        topic = "date",
        order = 70,
        patternID = "pnc.question.date",
        labelKey = "UI_PNC_Conversation_Suggestion_Date_Label",
        labelFallback = "Ask about the date",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Date_Utterance",
        utteranceFallback = "What's today's date?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "DATE",
        extensions = { topic = "date" },
    },
    {
        id = "question.weather",
        topic = "weather",
        order = 80,
        patternID = "pnc.question.weather",
        labelKey = "UI_PNC_Conversation_Suggestion_Weather_Label",
        labelFallback = "Ask about the weather",
        utteranceKey = "UI_PNC_Conversation_Suggestion_Weather_Utterance",
        utteranceFallback = "How is the weather?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "WEATHER",
        extensions = { topic = "weather" },
        hubID = "whats_up",
    },
}

function Provider.Find(id)
    for _, definition in ipairs(Provider.Definitions) do
        if definition.id == id then return definition end
    end
    return nil
end

local function hostileActor(actor)
    local roles = type(actor.roles) == "table" and actor.roles or {}
    local relationship = type(actor.relationship) == "table"
        and actor.relationship or {}
    local state = string.lower(tostring(relationship.state or ""))
    local role = string.lower(tostring(roles.role or ""))
    return roles.hostile == true or role == "enemy"
        or state == "enemy" or state == "rival"
end

local function ownedCompanion(actor)
    local roles = type(actor.roles) == "table" and actor.roles or {}
    return roles.companion == true and roles.owned == true
        and roles.authorityEligible == true
end

local function hasSafeGossip(context)
    local gossip = type(context.npcGossip) == "table"
        and context.npcGossip or nil
    if not gossip then
        local cognitionClient = PNC.Semantics.CognitionClient
        local npcID = tostring(context.npcID or "")
        if cognitionClient
            and type(cognitionClient.GetGossipContext) == "function"
            and npcID ~= ""
        then
            local ok, value = pcall(
                cognitionClient.GetGossipContext, npcID, "self"
            )
            if ok and type(value) == "table" then gossip = value end
        end
    end
    if not gossip or gossip.private == true or gossip.secret == true then
        return false
    end
    local visibility = string.lower(tostring(
        gossip.visibility or gossip.privacy or ""
    ))
    if visibility == "private" or visibility == "secret" then return false end
    local statements = type(gossip.statements) == "table"
        and gossip.statements or {}
    for index = 1, math.min(#statements, 4) do
        if type(statements[index]) == "string"
            and statements[index] ~= ""
        then
            return true
        end
    end
    return false
end

local function hubCandidate(definition, contextReason)
    local extensions = {}
    for key, value in pairs(type(definition.extensions) == "table"
        and definition.extensions or {}) do
        extensions[key] = value
    end
    extensions.route = "semantic_provider"
    extensions.providerID = Provider.id
    extensions.hubID = "whats_up"
    extensions.hubAvenue = true
    return {
        id = definition.id,
        topic = definition.topic,
        groupID = "semantic_hub.whats_up",
        rank = definition.order,
        providerID = Provider.id,
        semanticOwner = definition.semanticOwner
            or "projecthoomans.semantic." .. tostring(definition.topic),
        contextReason = contextReason,
        eligibility = {
            status = "allowed",
            allowed = true,
            reason = contextReason,
        },
        source = {
            kind = Provider.sourceKind,
            providerID = Provider.id,
            reason = "semantic_hub_avenue",
        },
        frame = {
            kind = "semantic_click_frame",
            candidateID = definition.id,
            topic = definition.topic,
            pattern = definition.patternID,
            intent = definition.intent,
            speechAct = definition.speechAct,
            action = definition.action,
            subject = definition.subject,
            target = definition.target,
            slots = definition.slots,
            modifiers = definition.modifiers,
            socialContext = definition.socialContext,
            extensions = extensions,
            textKey = definition.utteranceKey,
            textFallback = definition.utteranceFallback,
            labelKey = definition.labelKey,
        },
        display = {
            labelKey = definition.labelKey,
            labelFallback = definition.labelFallback,
            utteranceKey = definition.utteranceKey,
            utteranceFallback = definition.utteranceFallback,
        },
        visibility = "player",
    }
end

function Provider.collect(context)
    context = type(context) == "table" and context or {}
    if context.activeHubID ~= "whats_up" then
        return Provider.Definitions
    end

    local actor = type(context.actorConversationContext) == "table"
        and context.actorConversationContext or {}
    local hostile = hostileActor(actor)
    local owned = ownedCompanion(actor)
    local safeGossip = hasSafeGossip(context)
    local output = {}
    for _, definition in ipairs(Provider.Definitions) do
        if definition.hubID == "whats_up" then
            local allowed = not hostile
                or definition.id == "question.weather"
            local contextReason = hostile
                and "safe_public_weather_context"
                or "non_hostile_public_context"
            if definition.hubAudience == "owned_companion" then
                allowed = allowed and owned
                contextReason = owned and "owned_companion_context"
                    or "owned_companion_required"
            end
            if definition.hubRequiresSafeGossip then
                allowed = allowed and safeGossip
                contextReason = safeGossip and "player_safe_gossip_available"
                    or "safe_gossip_unavailable"
            end
            if allowed then
                output[#output + 1] = hubCandidate(definition, contextReason)
            end
        end
    end
    return output
end

return Provider
