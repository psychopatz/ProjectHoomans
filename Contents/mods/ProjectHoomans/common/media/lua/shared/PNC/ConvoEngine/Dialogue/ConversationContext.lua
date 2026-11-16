-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_context",
        ["exchangeFamily"] = {
            ["familyID"] = "conversation.context.replies",
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
                                ["fallback"] = "I don't know why that is; I only know what I can confirm.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.conversation.context.replies.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I don't know why that is; I only know what I can confirm.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko alam kung bakit ganoon; ang masasabi ko lang ay ang mga bagay na kumpirmado ko.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "conversation.context",
            ["textRoles"] = {
                {
                    ["fallback"] = "I don't know why that is; I only know what I can confirm.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.conversation.context.replies.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I don't know why that is; I only know what I can confirm.",
                        },
                        ["TL"] = {
                            "Hindi ko alam kung bakit ganoon; ang masasabi ko lang ay ang mga bagay na kumpirmado ko.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "conversation.context.replies",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "replies",
            ["sourceId"] = "conversation.context.replies",
            ["sourcePath"] = "dialogue/conversation_context/conversation_context_replies.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/ConversationContext",
        ["namespace"] = "conversation.context",
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
                        ["key"] = "UI_PNC_Conversation_Semantic_ContextReferenceCauseUnknown",
                        ["text"] = {
                            ["EN"] = "I don't know why that is; I only know what I can confirm.",
                            ["TL"] = "Hindi ko alam kung bakit ganoon; ang masasabi ko lang ay ang mga bagay na kumpirmado ko.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ContextReferenceDescriptionUnknown",
                        ["text"] = {
                            ["EN"] = "I don't know enough about that place to describe it.",
                            ["TL"] = "Wala akong sapat na alam tungkol sa lugar na iyon para mailarawan ito.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ContextReferenceLocationSafetyUnknown",
                        ["text"] = {
                            ["EN"] = "I don't have reliable information about whether it's safe there.",
                            ["TL"] = "Wala akong mapagkakatiwalaang impormasyon kung ligtas ba roon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ContextReferenceMedicalUnknown",
                        ["text"] = {
                            ["EN"] = "I can't confirm anything about that pain right now.",
                            ["TL"] = "Hindi ko makumpirma ang anumang sakit na iyon sa ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ContextReferenceUnknown",
                        ["text"] = {
                            ["EN"] = "I'm not sure what you're referring to.",
                            ["TL"] = "Hindi ko tiyak kung ano ang tinutukoy mo.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationAcknowledged",
                        ["text"] = {
                            ["EN"] = "All right. Ask if you want to talk about it more.",
                            ["TL"] = "Sige. Sabihin mo kung gusto mo pa itong pag-usapan.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationAcknowledgedFriendly",
                        ["text"] = {
                            ["EN"] = "All right. Ask if you want to talk about it more.",
                            ["TL"] = "Sige. Sabihin mo kung gusto mo pa itong pag-usapan.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationAcknowledgedWithdrawn",
                        ["text"] = {
                            ["EN"] = "All right. We can leave it there for now.",
                            ["TL"] = "Sige. Maaari nating iwan muna iyan.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationDefault",
                        ["text"] = {
                            ["EN"] = "I don't have anything else to add about that right now.",
                            ["TL"] = "Wala na akong ibang maidaragdag tungkol doon sa ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationGossipMemory",
                        ["text"] = {
                            ["EN"] = "That's all I know about it for now.",
                            ["TL"] = "Iyan na ang lahat ng alam ko tungkol dito sa ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationGossipUnknown",
                        ["text"] = {
                            ["EN"] = "I don't have anything else to add right now.",
                            ["TL"] = "Wala na akong ibang maidaragdag sa ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationKnowledge",
                        ["text"] = {
                            ["EN"] = "I don't have anything else reliable to add about that.",
                            ["TL"] = "Wala na akong ibang maaasahang maidaragdag tungkol doon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationMedical",
                        ["text"] = {
                            ["EN"] = "I can't confirm anything more about my health right now.",
                            ["TL"] = "Hindi ko makumpirma ang iba pa tungkol sa kalusugan ko ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationMedicalKnown",
                        ["text"] = {
                            ["EN"] = "I don't have anything more to add about my health right now.",
                            ["TL"] = "Wala na akong ibang maidaragdag tungkol sa kalusugan ko sa ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationMedicalUnknown",
                        ["text"] = {
                            ["EN"] = "I can't confirm anything more about my health right now.",
                            ["TL"] = "Hindi ko makumpirma ang iba pa tungkol sa kalusugan ko ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationResidence",
                        ["text"] = {
                            ["EN"] = "That's all I can confirm about where I live right now.",
                            ["TL"] = "Iyan lang ang makukumpirma ko tungkol sa tinitirhan ko sa ngayon.",
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
                                        "I don't know why that is; I only know what I can confirm.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko alam kung bakit ganoon; ang masasabi ko lang ay ang mga bagay na kumpirmado ko.",
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
            ["responsePlanID"] = "conversation.context.replies",
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
                            ["fallback"] = "I don't know why that is; I only know what I can confirm.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.conversation.context.replies.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/conversation_context/conversation_context_replies.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I don't know why that is; I only know what I can confirm.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.conversation.context.replies.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I don't know why that is; I only know what I can confirm.",
                    },
                    ["TL"] = {
                        "Hindi ko alam kung bakit ganoon; ang masasabi ko lang ay ang mga bagay na kumpirmado ko.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
