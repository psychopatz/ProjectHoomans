-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "identity_exchange",
        ["domainPath"] = "identity_exchange",
        ["exchangeFamily"] = {
            ["familyID"] = "identity.exchange.responses",
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
                                ["fallback"] = "That's a rude way to answer.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.identity.exchange.responses.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "identity.exchange",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's a rude way to answer.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.identity.exchange.responses.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "identity.exchange.responses",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "responses",
            ["sourceId"] = "identity.exchange.responses",
            ["sourcePath"] = "dialogue/identity_exchange/identity_exchange_responses.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/IdentityExchange",
        ["namespace"] = "identity.exchange",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["flow"] = {
                    ["id"] = "identity",
                    ["initial"] = "await_player_name",
                    ["nodes"] = {
                        ["await_player_name"] = {
                            ["accepts"] = {
                                {
                                    ["identityClaim"] = true,
                                    ["intent"] = "INFORM",
                                    ["subject"] = "IDENTITY",
                                },
                            },
                            ["onMatch"] = "complete",
                            ["onRefuse"] = "cancel",
                            ["onUnrelated"] = "suspend",
                            ["responsePool"] = "semantic.question.identity",
                            ["slots"] = {
                                ["name"] = {
                                    ["owner"] = "identity",
                                    ["source"] = "slots.identityClaim.name",
                                    ["type"] = "string",
                                },
                            },
                        },
                        ["complete"] = {
                            ["terminal"] = true,
                        },
                    },
                    ["owner"] = "ProjectHoomans",
                    ["version"] = 1,
                },
                ["textRows"] = {
                    {
                        ["fallback"] = "That's a rude way to answer.",
                        ["key"] = "UI_PNC_Conversation_Identity_Evasion_Rude_1",
                    },
                    {
                        ["fallback"] = "If you want my help, show some basic courtesy.",
                        ["key"] = "UI_PNC_Conversation_Identity_Evasion_Rude_2",
                    },
                    {
                        ["fallback"] = "Fine. Keep your name to yourself, then.",
                        ["key"] = "UI_PNC_Conversation_Identity_Evasion_Rude_3",
                    },
                    {
                        ["fallback"] = "I don't believe you.",
                        ["key"] = "UI_PNC_Conversation_Identity_FalseName",
                    },
                    {
                        ["fallback"] = "You avoided my question. That makes you seem untrustworthy.",
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityEvasionDefault",
                    },
                    {
                        ["fallback"] = "I asked you your name. Changing the subject makes me question your honesty.",
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityEvasionFriendly",
                    },
                    {
                        ["fallback"] = "You avoided my question. I can't trust you with my name.",
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityEvasionUntrustworthy",
                    },
                    {
                        ["fallback"] = "Forget it. Keep your name to yourself; I don't trust evasive people.",
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityEvasionWithdrawn",
                    },
                    {
                        ["fallback"] = "Nice to meet you. What's your name?",
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityExchange",
                    },
                    {
                        ["fallback"] = "Okay %s, nice to meet you. I'm %s.",
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityExchangeConfirmed",
                    },
                    {
                        ["fallback"] = "Okay %s, nice to meet you.",
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityExchangeConfirmedUnnamed",
                    },
                    {
                        ["fallback"] = "I couldn't verify your name just now. Could you tell me again?",
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityExchangeUnavailable",
                    },
                    {
                        ["fallback"] = "I'll tell you my name once we've established some trust. What's your name?",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentity",
                    },
                    {
                        ["fallback"] = "I'm %s. We already know each other.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityKnown",
                    },
                    {
                        ["fallback"] = "I'm %s. You should already know that.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityKnownGuarded",
                    },
                    {
                        ["fallback"] = "You know me. I'm %s.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityKnownTerse",
                    },
                    {
                        ["fallback"] = "I'm %s. Good to see you again.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityKnownWarm",
                    },
                    {
                        ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityStrangerAlt1",
                    },
                    {
                        ["fallback"] = "Let's get to know each other first. What do people call you?",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityStrangerAlt2",
                    },
                    {
                        ["fallback"] = "I don't share my name with liars. What's yours, truthfully?",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityWary",
                    },
                    {
                        ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityWaryAlt1",
                    },
                    {
                        ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityWaryAlt2",
                    },
                },
                ["textTarget"] = "convo/SemanticResponses",
                ["triggers"] = {
                    {
                        ["intent"] = "QUESTION",
                        ["subject"] = "IDENTITY",
                    },
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
                                ["fallback"] = "That's a rude way to answer.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "identity.exchange.responses",
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
                            ["fallback"] = "That's a rude way to answer.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.identity.exchange.responses.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/identity_exchange/identity_exchange_responses.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's a rude way to answer.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.identity.exchange.responses.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
