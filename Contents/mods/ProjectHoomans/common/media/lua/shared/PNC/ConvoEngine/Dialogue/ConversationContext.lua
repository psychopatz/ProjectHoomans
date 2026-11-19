-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_context",
        ["domainPath"] = "conversation_context",
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
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "conversation.context.replies",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "replies",
            ["sourceId"] = "conversation.context.replies",
            ["sourcePath"] = "dialogue/conversation_context/conversation_context_replies.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "I don't know why that is; I only know what I can confirm.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ContextReferenceCauseUnknown",
                    },
                    {
                        ["fallback"] = "I don't know enough about that place to describe it.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ContextReferenceDescriptionUnknown",
                    },
                    {
                        ["fallback"] = "I don't have reliable information about whether it's safe there.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ContextReferenceLocationSafetyUnknown",
                    },
                    {
                        ["fallback"] = "I can't confirm anything about that pain right now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ContextReferenceMedicalUnknown",
                    },
                    {
                        ["fallback"] = "I'm not sure what you're referring to.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ContextReferenceUnknown",
                    },
                    {
                        ["fallback"] = "All right. Ask if you want to talk about it more.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationAcknowledged",
                    },
                    {
                        ["fallback"] = "All right. Ask if you want to talk about it more.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationAcknowledgedFriendly",
                    },
                    {
                        ["fallback"] = "All right. We can leave it there for now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationAcknowledgedWithdrawn",
                    },
                    {
                        ["fallback"] = "I don't have anything else to add about that right now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationDefault",
                    },
                    {
                        ["fallback"] = "That's all I know about it for now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationGossipMemory",
                    },
                    {
                        ["fallback"] = "I don't have anything else to add right now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationGossipUnknown",
                    },
                    {
                        ["fallback"] = "I don't have anything else reliable to add about that.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationKnowledge",
                    },
                    {
                        ["fallback"] = "I can't confirm anything more about my health right now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationMedical",
                    },
                    {
                        ["fallback"] = "I don't have anything more to add about my health right now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationMedicalKnown",
                    },
                    {
                        ["fallback"] = "I can't confirm anything more about my health right now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationMedicalUnknown",
                    },
                    {
                        ["fallback"] = "That's all I can confirm about where I live right now.",
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationResidence",
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
                                ["fallback"] = "I don't know why that is; I only know what I can confirm.",
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
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
