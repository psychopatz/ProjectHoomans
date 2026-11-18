-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "question_residence",
        ["domainPath"] = "question_residence",
        ["exchangeFamily"] = {
            ["familyID"] = "question.residence.responses",
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
                                ["fallback"] = "That's all I can confirm about where I live right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.residence.responses.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's all I can confirm about where I live right now.",
                                    },
                                    ["TL"] = {
                                        "Iyan lang ang makukumpirma ko tungkol sa tinitirhan ko sa ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.residence",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's all I can confirm about where I live right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.residence.responses.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That's all I can confirm about where I live right now.",
                        },
                        ["TL"] = {
                            "Iyan lang ang makukumpirma ko tungkol sa tinitirhan ko sa ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.residence.responses",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "responses",
            ["sourceId"] = "question.residence.responses",
            ["sourcePath"] = "dialogue/question_residence/question_residence.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestionResidence",
        ["namespace"] = "question.residence",
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
                        ["key"] = "UI_PNC_Conversation_Semantic_ConversationContinuationResidence",
                        ["text"] = {
                            ["EN"] = "That's all I can confirm about where I live right now.",
                            ["TL"] = "Iyan lang ang makukumpirma ko tungkol sa tinitirhan ko sa ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionResidenceKnown",
                        ["text"] = {
                            ["EN"] = "I live at %s.",
                            ["TL"] = "Nakatira ako sa %s.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionResidenceUnknown",
                        ["text"] = {
                            ["EN"] = "I don't have a confirmed home to tell you about.",
                            ["TL"] = "Wala akong makumpirmang tirahan na maibabahagi.",
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
                                        "That's all I can confirm about where I live right now.",
                                    },
                                    ["TL"] = {
                                        "Iyan lang ang makukumpirma ko tungkol sa tinitirhan ko sa ngayon.",
                                    },
                                },
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
            ["responsePlanID"] = "question.residence.responses",
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
                            ["fallback"] = "That's all I can confirm about where I live right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.residence.responses.say_1",
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
        ["sourceShard"] = "dialogue/question_residence/question_residence.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's all I can confirm about where I live right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.residence.responses.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That's all I can confirm about where I live right now.",
                    },
                    ["TL"] = {
                        "Iyan lang ang makukumpirma ko tungkol sa tinitirhan ko sa ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
