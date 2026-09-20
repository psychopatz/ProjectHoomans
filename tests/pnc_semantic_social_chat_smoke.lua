local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local Policy = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local DialogueContext = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueContextState.lua"
)
local ResponseAdapter = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Presentation_Responses.lua"
)
local Presentation = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Presentation.lua"
)

local Parser = Semantic.Parser
local function parse(text)
    return Parser.Parse(text)
end

local complimentExamples = {
    "You look cute!",
    "You're really beautiful.",
    "I think you are so nice.",
    "I like your smile.",
    "You have very pretty eyes.",
}
local index
local ir
for index = 1, #complimentExamples do
    ir = parse(complimentExamples[index])
    T.equal(ir.intent, "COMPLIMENT",
        "clear direct compliment is recognized: " .. complimentExamples[index])
    T.equal(ir.speechAct, "COMPLIMENT",
        "compliment speech act remains typed")
    T.equal(ir.subject, "RECIPIENT",
        "compliment is directed at the NPC")
    T.equal(ir.diagnostics.recommendedRoute, "deterministic",
        "compliment uses the Lua route without an LLM")
end

T.falsy(parse("cute").intent == "COMPLIMENT",
    "a positive adjective alone is not treated as a compliment")
T.falsy(parse("I look cute").intent == "COMPLIMENT",
    "first-person appearance is not misattributed to the NPC")

local relationshipQuestions = {
    "Are you single?",
    "Are you taken?",
    "Are you seeing anyone?",
    "Are you in a relationship?",
    "Are you married?",
    "Do you have a partner?",
    "Do you have a boyfriend?",
    "Do you have a girlfriend?",
}
for index = 1, #relationshipQuestions do
    ir = parse(relationshipQuestions[index])
    T.equal(ir.intent, "QUESTION",
        "relationship-status phrase remains a question")
    T.equal(ir.subject, "RELATIONSHIP_STATUS",
        "relationship-status phrase receives its own subject")
    T.equal(ir.diagnostics.recommendedRoute, "deterministic",
        "relationship-status question stays local without an LLM")
end

local unrelatedSingle = parse("bring me a single apple")
T.falsy(unrelatedSingle.subject == "RELATIONSHIP_STATUS",
    "the word single in an item request is not a relationship question")

local acknowledgementExamples = {
    "I understand",
    "I understand what you mean",
    "I hear you",
    "I see what you mean",
    "Understood",
}
local acknowledgementIR
for index = 1, #acknowledgementExamples do
    acknowledgementIR = parse(acknowledgementExamples[index])
    T.equal(acknowledgementIR.intent, "ACKNOWLEDGE",
        "acknowledgment is recognized without granting consent: "
            .. acknowledgementExamples[index])
    T.equal(acknowledgementIR.speechAct, "ACKNOWLEDGE",
        "acknowledgment has a distinct speech act")
end
acknowledgementIR = parse("I understand")
T.falsy(acknowledgementIR.intent == "ACCEPT"
    or acknowledgementIR.intent == "AGREE",
    "understanding is not parsed as agreement or acceptance")

local state = Semantic.DialogueState.New({ participants = { "npc:mara" } })
local standaloneAcknowledgement = Policy.Decide(
    acknowledgementIR,
    state,
    { llmEnabled = false }
)
T.equal(standaloneAcknowledgement.branch, "SOCIAL_ACKNOWLEDGED",
    "acknowledgment uses the existing social response branch")
T.equal(standaloneAcknowledgement.response.templateID,
    "semantic.social.acknowledged",
    "an acknowledgment without matching dialogue context gets a generic reply")
local acknowledgementDuringGiftOffer = Policy.Decide(
    acknowledgementIR,
    state,
    {
        llmEnabled = false,
        pendingGiftConsent = {
            candidates = { { npcID = "npc:mara" } },
        },
    }
)
T.equal(acknowledgementDuringGiftOffer.giftConsent, nil,
    "acknowledgment cannot authorize a pending gift")

local compliment = parse("you look cute")
local complimentDecision = Policy.Decide(compliment, state, {
    llmEnabled = false,
    npcID = "npc:mara",
    socialStyle = "friendly",
})
T.equal(complimentDecision.route, "deterministic",
    "a compliment does not fall back to the LLM")
T.equal(complimentDecision.branch, "COMPLIMENT_RECEIVED",
    "a compliment selects its own dialogue branch")
T.equal(complimentDecision.response.templateID,
    "semantic.social.compliment.friendly",
    "friendly NPCs can return a light, noncommittal compliment")
T.equal(ResponseAdapter.Payload(complimentDecision).translationKey,
    "UI_PNC_Conversation_Semantic_ComplimentFriendly",
    "compliment response resolves through the conversation translation catalog")

local relationshipQuestion = parse("are you single")
local unknownStatus = Policy.Decide(relationshipQuestion, state, {
    llmEnabled = false,
    npcID = "npc:mara-unknown",
    socialStyle = "neutral",
    npcPersonality = { romanceStyle = "flirty" },
})
T.equal(unknownStatus.branch, "QUESTION_RECEIVED",
    "relationship status uses the existing question branch")
T.truthy(string.find(unknownStatus.response.templateID,
    "semantic.question.relationship_status", 1, true),
    "unknown relationship status selects a dedicated response")
T.falsy(string.find(string.lower(unknownStatus.response.fallback),
    "i'm single", 1, true),
    "missing relationship data is not turned into a claim of being single")
T.falsy(string.find(string.lower(unknownStatus.response.fallback),
    "i'm taken", 1, true),
    "romance style alone is not treated as evidence of a partner")
T.equal(ResponseAdapter.Payload(unknownStatus).translationKey ~= nil, true,
    "unknown status response has a localized conversation key")

local delayedComplimentHistory = {
    recentTurns = {
        { speaker = "npc", intent = "RESPONSE", speechAct = "ANSWER" },
        { speaker = "player", intent = "QUESTION", subject = "WEATHER" },
        {
            speaker = "npc",
            intent = "RESPONSE",
            speechAct = "COMPLIMENT_RESPONSE",
            branch = "COMPLIMENT_RECEIVED",
        },
        { speaker = "player", intent = "COMPLIMENT", speechAct = "COMPLIMENT" },
    },
}
local delayedComplimentStatus = Policy.Decide(
    relationshipQuestion,
    state,
    {
        llmEnabled = false,
        npcID = "npc:mara-unknown",
        socialStyle = "neutral",
        semanticDialogueContext = delayedComplimentHistory,
    }
)
T.falsy(string.find(delayedComplimentStatus.response.templateID,
    "after_compliment", 1, true),
    "a compliment from an older exchange is not treated as the immediate context")

local knownPartner = Policy.Decide(relationshipQuestion, state, {
    llmEnabled = false,
    npcID = "npc:mara-partner",
    relationshipState = "Lover",
})
T.equal(knownPartner.response.templateID,
    "semantic.question.relationship_status.committed",
    "an explicit Lover relationship supports a grounded partner answer")
T.contains(knownPartner.response.fallback, "already together",
    "the answer refers to the explicit player-NPC relationship")

local generatedPartner = Policy.Decide(relationshipQuestion, state, {
    llmEnabled = false,
    npcID = "npc:starter-partner",
    npcRecord = { generation = { relationshipKind = "lover" } },
})
T.equal(generatedPartner.response.templateID,
    "semantic.question.relationship_status.committed",
    "an authored companion relationship is recognized as known")

local contextState = DialogueContext.New()
local session = {
    conversationID = "social-chat-smoke",
    semanticDialogueContext = contextState,
    queueMessage = function(self, speaker, response, metadata)
        self.queued = {
            speaker = speaker,
            response = response,
            metadata = metadata,
        }
        return true
    end,
}
local view = {
    session = session,
    spec = {
        npcID = "npc:mara",
        context = { npcName = "Mara" },
    },
}
contextState:RecordTurn(compliment, {
    speaker = "player",
    source = "player_input",
})
T.equal(Presentation.Internal.QueueDeterministicResponse(
    view,
    compliment.rawText,
    { ir = compliment, decision = complimentDecision },
    nil,
    { speakerID = "npc:mara", speakerName = "Mara" }
), true, "compliment response is queued in the local dialogue")

local relationshipContext = contextState:ToContext()
local contextualUnknownStatus = Policy.Decide(
    relationshipQuestion,
    state,
    {
        llmEnabled = false,
        npcID = "npc:mara",
        socialStyle = "neutral",
        semanticDialogueContext = relationshipContext,
    }
)
T.truthy(string.find(contextualUnknownStatus.response.templateID,
    "after_compliment", 1, true),
    "a relationship question immediately following a compliment gets a contextual reply")
T.equal(ResponseAdapter.Payload(contextualUnknownStatus).translationKey ~= nil,
    true,
    "contextual reply resolves through the conversation translation catalog")
local contextualPartnerStatus = Policy.Decide(
    relationshipQuestion,
    state,
    {
        llmEnabled = false,
        npcID = "npc:mara-partner",
        relationshipState = "Lover",
        semanticDialogueContext = relationshipContext,
    }
)
T.equal(contextualPartnerStatus.response.templateID,
    "semantic.question.relationship_status.after_compliment.committed",
    "a known partner status acknowledges both the compliment and relationship")

contextState:RecordTurn(relationshipQuestion, {
    speaker = "player",
    source = "player_input",
})
T.equal(Presentation.Internal.QueueDeterministicResponse(
    view,
    relationshipQuestion.rawText,
    { ir = relationshipQuestion, decision = contextualUnknownStatus },
    nil,
    { speakerID = "npc:mara", speakerName = "Mara" }
), true, "local response is queued")

local recent = contextState:RecentTurns(4, true)
T.equal(#recent, 4, "bounded context includes both player and NPC turns")
T.equal(recent[1].speaker, "npc",
    "the newest typed context event is the NPC answer")
T.equal(recent[1].speakerID, "npc:mara",
    "the event identifies which NPC spoke")
T.equal(recent[1].intent, "RESPONSE",
    "the NPC message is typed as a response")
T.equal(recent[1].subject, "RELATIONSHIP_STATUS",
    "the answer remains linked to the question subject")
T.equal(recent[1].branch, "QUESTION_RECEIVED",
    "the event retains the deterministic response branch")
T.equal(recent[2].speaker, "player",
    "the relationship question is retained before its answer")
T.equal(recent[3].speaker, "npc",
    "the compliment exchange keeps the NPC's earlier response")
T.equal(recent[3].speechAct, "COMPLIMENT_RESPONSE",
    "the NPC's earlier compliment reply remains typed")
T.equal(recent[4].speaker, "player",
    "the earlier player compliment remains in the multi-turn history")
T.equal(contextState.lastIntent, "QUESTION",
    "recording the NPC reply does not replace the last player intent")
T.equal(contextState.lastSpeaker, "npc",
    "turn context tracks the latest speaker")
T.truthy(session.queued and session.queued.response.text,
    "the queued NPC message contains display-ready text")

contextState:RecordTurn(acknowledgementIR, {
    speaker = "player",
    source = "player_input",
})
local contextualAcknowledgement = Policy.Decide(
    acknowledgementIR,
    state,
    {
        llmEnabled = false,
        npcID = "npc:mara",
        semanticDialogueContext = contextState:ToContext(),
    }
)
T.truthy(string.find(
    contextualAcknowledgement.response.templateID,
    "semantic.question.relationship_status.acknowledged",
    1,
    true
), "understanding receives a context-aware relationship reply")
T.truthy(ResponseAdapter.Payload(contextualAcknowledgement).translationKey,
    "context-aware acknowledgment resolves to a localized response")

local unrelatedAcknowledgementContext = {
    recentTurns = {
        { speaker = "player", intent = "ACKNOWLEDGE" },
        {
            speaker = "npc",
            speechAct = "ANSWER",
            subject = "WEATHER",
            branch = "QUESTION_RECEIVED",
        },
        { speaker = "player", intent = "QUESTION", subject = "WEATHER" },
        {
            speaker = "npc",
            speechAct = "ANSWER",
            subject = "RELATIONSHIP_STATUS",
            branch = "QUESTION_RECEIVED",
        },
    },
}
local unrelatedAcknowledgement = Policy.Decide(
    acknowledgementIR,
    state,
    {
        llmEnabled = false,
        semanticDialogueContext = unrelatedAcknowledgementContext,
    }
)
T.equal(unrelatedAcknowledgement.response.templateID,
    "semantic.social.acknowledged",
    "an older relationship answer does not trigger a contextual response")
T.equal(Presentation.Internal.QueueDeterministicResponse(
    view,
    acknowledgementIR.rawText,
    { ir = acknowledgementIR, decision = contextualAcknowledgement },
    nil,
    { speakerID = "npc:mara", speakerName = "Mara" }
), true, "the context-aware acknowledgment is queued")

local completedExchange = contextState:RecentTurns(6, true)
T.equal(#completedExchange, 6,
    "the bounded transcript retains the six-turn social exchange")
T.equal(completedExchange[1].speaker, "npc",
    "the NPC acknowledgment follows the player's understanding")
T.equal(completedExchange[1].topic, "RELATIONSHIP_STATUS",
    "the NPC response keeps the relationship topic across acknowledgment")
T.equal(contextState.lastIntent, "ACKNOWLEDGE",
    "the NPC response does not replace the player's acknowledgment intent")

local identityQuestion = parse("what's your name")
local identityContext = DialogueContext.New()
identityContext:RecordTurn(identityQuestion, { speaker = "player" })
identityContext:RecordNPCResponse({
    intent = "RESPONSE",
    speechAct = "ANSWER",
    subject = "IDENTITY",
    rawText = "I'll tell you after you tell me yours.",
})
T.equal(identityContext.pendingIdentityExchange.kind, "PLAYER_NAME",
    "an NPC reply leaves a pending identity exchange available for the next player turn")

T.finish("pnc_semantic_social_chat_smoke")
