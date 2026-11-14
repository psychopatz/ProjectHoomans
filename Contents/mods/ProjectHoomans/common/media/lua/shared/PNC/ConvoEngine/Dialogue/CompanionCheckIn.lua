-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_check_in",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "gossip",
                },
                ["labelFallback"] = "Ask about gossip",
                ["labelKey"] = "convo.question.gossip.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about gossip",
                    },
                    ["TL"] = {
                        "Magtanong tungkol sa tsismis",
                    },
                },
            },
            ["familyID"] = "question.gossip",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Any gossip?",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.gossip.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
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
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "GOSSIP",
                ["patternID"] = "pnc.social.gossip_event",
                ["speechAct"] = "GOSSIP",
                ["subject"] = "GOSSIP",
                ["topic"] = "gossip",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask about gossip",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.question.gossip.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask about gossip",
                        },
                        ["TL"] = {
                            "Magtanong tungkol sa tsismis",
                        },
                    },
                },
                {
                    ["fallback"] = "Any gossip?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.gossip.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Any gossip?",
                        },
                        ["TL"] = {
                            "May narinig ka bang tsismis?",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "question.gossip",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "gossip",
            ["sourceId"] = "question.gossip",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_check_in/question_gossip.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCheckIn",
        ["namespace"] = "question",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "gossip",
                },
                ["label"] = {
                    ["EN"] = {
                        "Ask about gossip",
                    },
                    ["TL"] = {
                        "Magtanong tungkol sa tsismis",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["invoke"] = {
                ["intent"] = "GOSSIP",
                ["patternID"] = "pnc.social.gossip_event",
                ["speechAct"] = "GOSSIP",
                ["subject"] = "GOSSIP",
                ["topic"] = "gossip",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["domain"] = "gossip",
                    ["extensions"] = {
                        ["topic"] = "gossip",
                    },
                    ["hubID"] = "whats_up",
                    ["hubOnly"] = true,
                    ["hubRequiresSafeGossip"] = true,
                    ["id"] = "question.gossip",
                    ["intent"] = "GOSSIP",
                    ["order"] = 70,
                    ["patternID"] = "pnc.social.gossip_event",
                    ["speechAct"] = "GOSSIP",
                    ["subject"] = "GOSSIP",
                    ["topic"] = "gossip",
                },
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "default",
                                ["text"] = {
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
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.gossip",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Any gossip?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.gossip.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_check_in/question_gossip.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask about gossip",
                ["role"] = "button_label",
                ["templateID"] = "convo.question.gossip.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about gossip",
                    },
                    ["TL"] = {
                        "Magtanong tungkol sa tsismis",
                    },
                },
            },
            {
                ["fallback"] = "Any gossip?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.gossip.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Any gossip?",
                    },
                    ["TL"] = {
                        "May narinig ka bang tsismis?",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_check_in",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "medical",
                },
                ["labelFallback"] = "Ask about injuries",
                ["labelKey"] = "convo.question.health.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about injuries",
                    },
                    ["TL"] = {
                        "Itanong ang mga sugat",
                    },
                },
                ["utility"] = {
                    ["care"] = 1.2,
                },
            },
            ["familyID"] = "question.health",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Are you hurt?",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.health.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Are you hurt?",
                                    },
                                    ["TL"] = {
                                        "Nasaktan ka ba?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.health.are_you_hurt",
                ["speechAct"] = "QUESTION",
                ["subject"] = "NPC_HEALTH_STATE",
                ["topic"] = "medical",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask about injuries",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.question.health.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask about injuries",
                        },
                        ["TL"] = {
                            "Itanong ang mga sugat",
                        },
                    },
                },
                {
                    ["fallback"] = "Are you hurt?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.health.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Are you hurt?",
                        },
                        ["TL"] = {
                            "Nasaktan ka ba?",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "question.health",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "health",
            ["sourceId"] = "question.health",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_check_in/question_health.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCheckIn",
        ["namespace"] = "question",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "medical",
                },
                ["label"] = {
                    ["EN"] = {
                        "Ask about injuries",
                    },
                    ["TL"] = {
                        "Itanong ang mga sugat",
                    },
                },
                ["textRole"] = "button_label",
                ["utility"] = {
                    ["care"] = 1.2,
                },
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.health.are_you_hurt",
                ["speechAct"] = "QUESTION",
                ["subject"] = "NPC_HEALTH_STATE",
                ["topic"] = "medical",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["domain"] = "medical",
                    ["extensions"] = {
                        ["topic"] = "medical",
                    },
                    ["hubAudience"] = "owned_companion",
                    ["hubID"] = "whats_up",
                    ["id"] = "question.health",
                    ["intent"] = "QUESTION",
                    ["order"] = 40,
                    ["patternID"] = "pnc.question.health.are_you_hurt",
                    ["slots"] = {
                        ["attribute"] = "health_state",
                    },
                    ["speechAct"] = "QUESTION",
                    ["subject"] = "NPC_HEALTH_STATE",
                    ["target"] = "SELF",
                    ["topic"] = "medical",
                },
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "default",
                                ["text"] = {
                                    ["EN"] = {
                                        "Are you hurt?",
                                    },
                                    ["TL"] = {
                                        "Nasaktan ka ba?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.health",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Are you hurt?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.health.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_check_in/question_health.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask about injuries",
                ["role"] = "button_label",
                ["templateID"] = "convo.question.health.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about injuries",
                    },
                    ["TL"] = {
                        "Itanong ang mga sugat",
                    },
                },
            },
            {
                ["fallback"] = "Are you hurt?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.health.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Are you hurt?",
                    },
                    ["TL"] = {
                        "Nasaktan ka ba?",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "companion_check_in",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "needs",
                },
                ["labelFallback"] = "Ask about needs",
                ["labelKey"] = "convo.question.needs.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about needs",
                    },
                    ["TL"] = {
                        "Itanong ang pangangailangan",
                    },
                },
                ["utility"] = {
                    ["care"] = 1,
                },
            },
            ["familyID"] = "question.needs",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Do you need anything?",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.needs.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Do you need anything?",
                                    },
                                    ["TL"] = {
                                        "May kailangan ka ba?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.needs_offer_plain",
                ["speechAct"] = "QUESTION",
                ["subject"] = "NEEDS",
                ["topic"] = "needs",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask about needs",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.question.needs.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask about needs",
                        },
                        ["TL"] = {
                            "Itanong ang pangangailangan",
                        },
                    },
                },
                {
                    ["fallback"] = "Do you need anything?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.needs.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "Do you need anything?",
                        },
                        ["TL"] = {
                            "May kailangan ka ba?",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "question.needs",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "needs",
            ["sourceId"] = "question.needs",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_check_in/question_needs.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCheckIn",
        ["namespace"] = "question",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "needs",
                },
                ["label"] = {
                    ["EN"] = {
                        "Ask about needs",
                    },
                    ["TL"] = {
                        "Itanong ang pangangailangan",
                    },
                },
                ["textRole"] = "button_label",
                ["utility"] = {
                    ["care"] = 1,
                },
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.needs_offer_plain",
                ["speechAct"] = "QUESTION",
                ["subject"] = "NEEDS",
                ["topic"] = "needs",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["dialogueFollowUp"] = "NEEDS_QUANTITY",
                    ["domain"] = "needs",
                    ["hubAudience"] = "owned_companion",
                    ["hubID"] = "whats_up",
                    ["id"] = "question.needs",
                    ["intent"] = "QUESTION",
                    ["order"] = 30,
                    ["patternID"] = "pnc.question.needs_offer_plain",
                    ["speechAct"] = "QUESTION",
                    ["subject"] = "NEEDS",
                    ["topic"] = "needs",
                },
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "default",
                                ["text"] = {
                                    ["EN"] = {
                                        "Do you need anything?",
                                    },
                                    ["TL"] = {
                                        "May kailangan ka ba?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.needs",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Do you need anything?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.needs.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_check_in/question_needs.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask about needs",
                ["role"] = "button_label",
                ["templateID"] = "convo.question.needs.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about needs",
                    },
                    ["TL"] = {
                        "Itanong ang pangangailangan",
                    },
                },
            },
            {
                ["fallback"] = "Do you need anything?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.needs.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "Do you need anything?",
                    },
                    ["TL"] = {
                        "May kailangan ka ba?",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
