-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "medical",
        ["extensions"] = {
            ["topic"] = "medical",
        },
        ["hubAudience"] = "owned_companion",
        ["hubID"] = "whats_up",
        ["id"] = "question.health",
        ["intent"] = "QUESTION",
        ["labelFallback"] = "Are you hurt?",
        ["labelKey"] = "UI_PNC_Conversation_Suggestion_Health_Label",
        ["order"] = 40,
        ["patternID"] = "pnc.question.health.are_you_hurt",
        ["slots"] = {
            ["attribute"] = "health_state",
        },
        ["speechAct"] = "QUESTION",
        ["subject"] = "NPC_HEALTH_STATE",
        ["target"] = "SELF",
        ["topic"] = "medical",
        ["translations"] = {
            ["EN"] = {
                ["label"] = "Ask about injuries",
                ["utterance"] = "Are you hurt?",
            },
            ["TL"] = {
                ["label"] = "Itanong ang mga sugat",
                ["utterance"] = "Nasaktan ka ba?",
            },
        },
        ["utteranceFallback"] = "Are you hurt?",
        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_Health_Utterance",
    },
}
