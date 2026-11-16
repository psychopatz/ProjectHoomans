-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "identity_exchange",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's a rude way to answer.",
                                    },
                                    ["TL"] = {
                                        "Ang bastos naman ng sagot mo.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "That's a rude way to answer.",
                        },
                        ["TL"] = {
                            "Ang bastos naman ng sagot mo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "identity.exchange.responses",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "responses",
            ["sourceId"] = "identity.exchange.responses",
            ["sourcePath"] = "adopters/hoomans/dialogue/identity_exchange/identity_exchange_responses.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "UI_PNC_Conversation_Identity_Evasion_Rude_1",
                        ["text"] = {
                            ["EN"] = "That's a rude way to answer.",
                            ["TL"] = "Ang bastos naman ng sagot mo.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Identity_Evasion_Rude_2",
                        ["text"] = {
                            ["EN"] = "If you want my help, show some basic courtesy.",
                            ["TL"] = "Kung gusto mo ng tulong ko, magpakita ka ng kaunting paggalang.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Identity_Evasion_Rude_3",
                        ["text"] = {
                            ["EN"] = "Fine. Keep your name to yourself, then.",
                            ["TL"] = "Sige. Sarili mo na lang ang pangalan mo.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Identity_FalseName",
                        ["text"] = {
                            ["EN"] = "I don't believe you.",
                            ["TL"] = "Hindi ako naniniwala sa iyo.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityEvasionDefault",
                        ["text"] = {
                            ["EN"] = "You avoided my question. That makes you seem untrustworthy.",
                            ["TL"] = "Iniwasan mo ang tanong ko. Nagmumukha kang hindi mapagkakatiwalaan.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityEvasionFriendly",
                        ["text"] = {
                            ["EN"] = "I asked you your name. Changing the subject makes me question your honesty.",
                            ["TL"] = "Tinanong ko ang pangalan mo. Dahil binago mo ang paksa, nagdududa ako sa katapatan mo.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityEvasionUntrustworthy",
                        ["text"] = {
                            ["EN"] = "You avoided my question. I can't trust you with my name.",
                            ["TL"] = "Iniwasan mo ang tanong ko. Hindi kita mapagkakatiwalaan sa pangalan ko.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityEvasionWithdrawn",
                        ["text"] = {
                            ["EN"] = "Forget it. Keep your name to yourself; I don't trust evasive people.",
                            ["TL"] = "Sige na. Itago mo ang pangalan mo; hindi ako nagtitiwala sa mga umiiwas.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityExchange",
                        ["text"] = {
                            ["EN"] = "Nice to meet you. What's your name?",
                            ["TL"] = "Ikinagagalak kitang makilala. Ano ang pangalan mo?",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityExchangeConfirmed",
                        ["text"] = {
                            ["EN"] = "Okay %s, nice to meet you. I'm %s.",
                            ["TL"] = "Sige, %s. Ikinagagalak kitang makilala. Ako si %s.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityExchangeConfirmedUnnamed",
                        ["text"] = {
                            ["EN"] = "Okay %s, nice to meet you.",
                            ["TL"] = "Sige, %s. Ikinagagalak kitang makilala.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_IdentityExchangeUnavailable",
                        ["text"] = {
                            ["EN"] = "I couldn't verify your name just now. Could you tell me again?",
                            ["TL"] = "Hindi ko makumpirma ang pangalan mo sa ngayon. Maaari mo bang sabihin itong muli?",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentity",
                        ["text"] = {
                            ["EN"] = "I'll tell you my name once we've established some trust. What's your name?",
                            ["TL"] = "Sasabihin ko ang pangalan ko kapag may tiwala na tayo. Ano ang pangalan mo?",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityKnown",
                        ["text"] = {
                            ["EN"] = "I'm %s. We already know each other.",
                            ["TL"] = "Ako si %s. Kilala na natin ang isa't isa.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityKnownGuarded",
                        ["text"] = {
                            ["EN"] = "I'm %s. You should already know that.",
                            ["TL"] = "Ako si %s. Dapat kilala mo na ako.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityKnownTerse",
                        ["text"] = {
                            ["EN"] = "You know me. I'm %s.",
                            ["TL"] = "Kilala mo ako. Ako si %s.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityKnownWarm",
                        ["text"] = {
                            ["EN"] = "I'm %s. Good to see you again.",
                            ["TL"] = "Ako si %s. Mabuti at nakita kita ulit.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityStrangerAlt1",
                        ["text"] = {
                            ["EN"] = "I keep my name to myself until I know someone better. What should I call you?",
                            ["TL"] = "Hindi ko muna sasabihin ang pangalan ko hangga't hindi pa kita lubos na kilala. Ano ang itatawag ko sa iyo?",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityStrangerAlt2",
                        ["text"] = {
                            ["EN"] = "Let's get to know each other first. What do people call you?",
                            ["TL"] = "Kilalanin muna natin ang isa't isa. Ano ang tawag sa iyo?",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityWary",
                        ["text"] = {
                            ["EN"] = "I don't share my name with liars. What's yours, truthfully?",
                            ["TL"] = "Hindi ko ibinabahagi ang pangalan ko sa mga sinungaling. Ano ang tunay mong pangalan?",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityWaryAlt1",
                        ["text"] = {
                            ["EN"] = "I don't trust you enough to share my name. Who are you, really?",
                            ["TL"] = "Hindi pa kita pinagkakatiwalaan para sabihin ang pangalan ko. Sino ka ba talaga?",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionIdentityWaryAlt2",
                        ["text"] = {
                            ["EN"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                            ["TL"] = "Pagkatapos mong magsinungaling, hindi ko sasabihin ang pangalan ko. Sabihin mo muna ang totoo tungkol sa iyo.",
                        },
                    },
                },
                ["textTarget"] = "convo/SemanticResponses",
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "That's a rude way to answer.",
                                    },
                                    ["TL"] = {
                                        "Ang bastos naman ng sagot mo.",
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
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/identity_exchange/identity_exchange_responses.json",
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
                ["translations"] = {
                    ["EN"] = {
                        "That's a rude way to answer.",
                    },
                    ["TL"] = {
                        "Ang bastos naman ng sagot mo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
