-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_check_in",
        ["id"] = "social.companion_check_in",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "social.companion_check_in",
            ["sourcePath"] = "psdl/dialogue/companion_check_in.json",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCheckIn",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
            },
            ["offers"] = {
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["dialogueFollowUp"] = "NEEDS_QUANTITY",
                        ["hubAudience"] = "owned_companion",
                        ["hubID"] = "whats_up",
                        ["intent"] = "QUESTION",
                        ["patternID"] = "pnc.question.needs_offer_plain",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "NEEDS",
                        ["topic"] = "needs",
                    },
                    ["id"] = "question.needs",
                    ["label"] = {
                        ["EN"] = {
                            "Ask about needs",
                        },
                        ["TL"] = {
                            "Itanong ang pangangailangan",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "needs",
                        ["order"] = 30,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "Do you need anything?",
                        },
                        ["TL"] = {
                            "May kailangan ka ba?",
                        },
                    },
                },
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["extensions"] = {
                            ["topic"] = "medical",
                        },
                        ["hubAudience"] = "owned_companion",
                        ["hubID"] = "whats_up",
                        ["intent"] = "QUESTION",
                        ["patternID"] = "pnc.question.health.are_you_hurt",
                        ["slots"] = {
                            ["attribute"] = "health_state",
                        },
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "NPC_HEALTH_STATE",
                        ["target"] = "SELF",
                        ["topic"] = "medical",
                    },
                    ["id"] = "question.health",
                    ["label"] = {
                        ["EN"] = {
                            "Ask about injuries",
                        },
                        ["TL"] = {
                            "Itanong ang mga sugat",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "medical",
                        ["order"] = 40,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "Are you hurt?",
                        },
                        ["TL"] = {
                            "Nasaktan ka ba?",
                        },
                    },
                },
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["extensions"] = {
                            ["topic"] = "gossip",
                        },
                        ["hubID"] = "whats_up",
                        ["hubOnly"] = true,
                        ["hubRequiresSafeGossip"] = true,
                        ["intent"] = "GOSSIP",
                        ["patternID"] = "pnc.social.gossip_event",
                        ["speechAct"] = "GOSSIP",
                        ["subject"] = "GOSSIP",
                        ["topic"] = "gossip",
                    },
                    ["id"] = "question.gossip",
                    ["label"] = {
                        ["EN"] = {
                            "Ask about gossip",
                        },
                        ["TL"] = {
                            "Magtanong tungkol sa tsismis",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "gossip",
                        ["order"] = 70,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "Any gossip?",
                        },
                        ["TL"] = {
                            "May narinig ka bang tsismis?",
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/companion_check_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
