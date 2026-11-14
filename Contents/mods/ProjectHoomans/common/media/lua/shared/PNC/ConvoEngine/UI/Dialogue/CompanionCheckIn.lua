-- Generated; do not edit by hand.
return {
    {
        ["dialogueFollowUp"] = "NEEDS_QUANTITY",
        ["display"] = {
            ["EN"] = {
                ["label"] = "Ask about needs",
                ["utterance"] = "Do you need anything?",
            },
            ["TL"] = {
                ["label"] = "Itanong ang pangangailangan",
                ["utterance"] = "May kailangan ka ba?",
            },
        },
        ["domain"] = "needs",
        ["hubAudience"] = "owned_companion",
        ["hubID"] = "whats_up",
        ["id"] = "question.needs",
        ["intent"] = "QUESTION",
        ["labelFallback"] = "Ask about needs",
        ["labelKey"] = "UI_PNC_Conversation_Suggestion_Needs_Label",
        ["order"] = 30,
        ["patternID"] = "pnc.question.needs_offer_plain",
        ["speechAct"] = "QUESTION",
        ["subject"] = "NEEDS",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["topic"] = "needs",
        ["utteranceFallback"] = "Do you need anything?",
        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_Needs_Utterance",
    },
    {
        ["display"] = {
            ["EN"] = {
                ["label"] = "Ask about injuries",
                ["utterance"] = "Are you hurt?",
            },
            ["TL"] = {
                ["label"] = "Itanong ang mga sugat",
                ["utterance"] = "Nasaktan ka ba?",
            },
        },
        ["domain"] = "medical",
        ["extensions"] = {
            ["topic"] = "medical",
        },
        ["hubAudience"] = "owned_companion",
        ["hubID"] = "whats_up",
        ["id"] = "question.health",
        ["intent"] = "QUESTION",
        ["labelFallback"] = "Ask about injuries",
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
        ["utteranceFallback"] = "Are you hurt?",
        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_Health_Utterance",
    },
    {
        ["display"] = {
            ["EN"] = {
                ["label"] = "Ask about gossip",
                ["utterance"] = "Any gossip?",
            },
            ["TL"] = {
                ["label"] = "Magtanong tungkol sa tsismis",
                ["utterance"] = "May narinig ka bang tsismis?",
            },
        },
        ["domain"] = "gossip",
        ["extensions"] = {
            ["topic"] = "gossip",
        },
        ["hubID"] = "whats_up",
        ["hubOnly"] = true,
        ["hubRequiresSafeGossip"] = true,
        ["id"] = "question.gossip",
        ["intent"] = "GOSSIP",
        ["labelFallback"] = "Ask about gossip",
        ["labelKey"] = "UI_PNC_Conversation_Suggestion_Gossip_Label",
        ["order"] = 70,
        ["patternID"] = "pnc.social.gossip_event",
        ["speechAct"] = "GOSSIP",
        ["subject"] = "GOSSIP",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["topic"] = "gossip",
        ["utteranceFallback"] = "Any gossip?",
        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_Gossip_Utterance",
    },
}
