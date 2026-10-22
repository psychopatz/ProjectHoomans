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
        id = "conversation.whats_up",
        topic = "whats_up",
        order = 5,
        patternID = "pnc.dataset.question.whats_up.whats_up",
        labelKey = "UI_PNC_Conversation_Suggestion_WhatsUp_Label",
        labelFallback = "Ask what's up",
        utteranceKey = "UI_PNC_Conversation_Suggestion_WhatsUp_Utterance",
        utteranceFallback = "What's up?",
        intent = "QUESTION",
        speechAct = "QUESTION",
        subject = "CONVERSATION_TOPIC",
        extensions = {
            topic = "whats_up",
            categoryID = "projecthoomans:whats_up",
            route = "conversation_category",
        },
    },
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
        extensions = { topic = "medical" },
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
    },
}

function Provider.Find(id)
    for _, definition in ipairs(Provider.Definitions) do
        if definition.id == id then return definition end
    end
    return nil
end

function Provider.collect()
    return Provider.Definitions
end

return Provider
