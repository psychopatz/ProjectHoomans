-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_facts",
        ["domainPath"] = "core_knowledge_facts",
        ["exchangeFamily"] = {
            ["familyID"] = "question.knowledge_and_bite.responses",
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
                                ["fallback"] = "I know about %s.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.knowledge_and_bite.responses.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.knowledge_and_bite",
            ["textRoles"] = {
                {
                    ["fallback"] = "I know about %s.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.knowledge_and_bite.responses.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.knowledge_and_bite.responses",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "responses",
            ["sourceId"] = "question.knowledge_and_bite.responses",
            ["sourcePath"] = "dialogue/core_knowledge_facts/question_knowledge_and_bite_responses.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeFacts",
        ["namespace"] = "question.knowledge_and_bite",
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
                        ["fallback"] = "I know about %s.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionKnowledgeKnown",
                    },
                    {
                        ["fallback"] = "I don't have reliable information about %s.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionKnowledgeUnknown",
                    },
                    {
                        ["fallback"] = "No, I don't have a recorded bite.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionMedicalBiteNegative",
                    },
                    {
                        ["fallback"] = "Yes, I've been bitten.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionMedicalBitePositive",
                    },
                    {
                        ["fallback"] = "I can't confirm whether I've been bitten.",
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionMedicalBiteUnknown",
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
                                ["fallback"] = "I know about %s.",
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
            ["responsePlanID"] = "question.knowledge_and_bite.responses",
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
                            ["fallback"] = "I know about %s.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.knowledge_and_bite.responses.say_1",
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
        ["sourceShard"] = "dialogue/core_knowledge_facts/question_knowledge_and_bite_responses.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I know about %s.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.knowledge_and_bite.responses.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
