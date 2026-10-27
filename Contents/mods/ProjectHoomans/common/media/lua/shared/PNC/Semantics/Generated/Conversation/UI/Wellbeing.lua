-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing",
        ["hubID"] = "whats_up",
        ["id"] = "question.wellbeing",
        ["intent"] = "QUESTION",
        ["labelFallback"] = "How are you feeling?",
        ["labelKey"] = "UI_PNC_Conversation_Suggestion_Wellbeing_Label",
        ["order"] = 10,
        ["patternID"] = "pnc.question.wellbeing_feeling",
        ["speechAct"] = "QUESTION",
        ["subject"] = "WELLBEING",
        ["topic"] = "wellbeing",
        ["translations"] = {
            ["EN"] = {
                ["label"] = "Ask about wellbeing",
                ["utterance"] = "How are you feeling?",
            },
            ["TL"] = {
                ["label"] = "Itanong ang kalagayan",
                ["utterance"] = "Kumusta ang pakiramdam mo?",
            },
        },
        ["utteranceFallback"] = "How are you feeling?",
        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_Wellbeing_Utterance",
    },
    {
        ["domain"] = "wellbeing",
        ["extensions"] = {
            ["dialogueFollowUp"] = "WELLBEING",
        },
        ["id"] = "question.wellbeing_detail",
        ["intent"] = "QUESTION",
        ["labelFallback"] = "Can you tell me more?",
        ["labelKey"] = "UI_PNC_Conversation_Suggestion_WellbeingDetail_Label",
        ["order"] = 20,
        ["patternID"] = "pnc.question.wellbeing_follow_up_what_is_wrong",
        ["slots"] = {
            ["followUp"] = true,
        },
        ["speechAct"] = "QUESTION",
        ["subject"] = "WELLBEING",
        ["topic"] = "wellbeing",
        ["translations"] = {
            ["EN"] = {
                ["label"] = "Ask what is wrong",
                ["utterance"] = "What's wrong?",
            },
            ["TL"] = {
                ["label"] = "Itanong kung ano ang problema",
                ["utterance"] = "Ano ang problema?",
            },
        },
        ["utteranceFallback"] = "What's wrong?",
        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_WellbeingDetail_Utterance",
    },
}
