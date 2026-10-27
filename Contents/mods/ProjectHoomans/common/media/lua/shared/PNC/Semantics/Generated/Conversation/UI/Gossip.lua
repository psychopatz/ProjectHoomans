-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "gossip",
        ["extensions"] = {
            ["topic"] = "gossip",
        },
        ["hubID"] = "whats_up",
        ["hubOnly"] = true,
        ["hubRequiresSafeGossip"] = true,
        ["id"] = "question.gossip",
        ["intent"] = "GOSSIP",
        ["labelFallback"] = "Heard any gossip?",
        ["labelKey"] = "UI_PNC_Conversation_Suggestion_Gossip_Label",
        ["order"] = 70,
        ["patternID"] = "pnc.social.gossip_event",
        ["speechAct"] = "GOSSIP",
        ["subject"] = "GOSSIP",
        ["topic"] = "gossip",
        ["translations"] = {
            ["EN"] = {
                ["label"] = "Ask about gossip",
                ["utterance"] = "Any gossip?",
            },
            ["TL"] = {
                ["label"] = "Magtanong tungkol sa tsismis",
                ["utterance"] = "May narinig ka bang tsismis?",
            },
        },
        ["utteranceFallback"] = "Any gossip?",
        ["utteranceKey"] = "UI_PNC_Conversation_Suggestion_Gossip_Utterance",
    },
}
