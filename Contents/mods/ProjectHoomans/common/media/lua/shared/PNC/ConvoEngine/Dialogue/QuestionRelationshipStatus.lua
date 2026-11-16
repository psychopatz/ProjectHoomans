-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "question_relationship_status",
        ["exchangeFamily"] = {
            ["familyID"] = "question.relationship_status.responses",
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
                                ["fallback"] = "That's kind of you to ask. I don't have a clear answer right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.relationship_status.responses.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's kind of you to ask. I don't have a clear answer right now.",
                                    },
                                    ["TL"] = {
                                        "Mabait mong itanong iyan. Wala pa akong malinaw na sagot sa ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.relationship_status",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's kind of you to ask. I don't have a clear answer right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.relationship_status.responses.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That's kind of you to ask. I don't have a clear answer right now.",
                        },
                        ["TL"] = {
                            "Mabait mong itanong iyan. Wala pa akong malinaw na sagot sa ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "question.relationship_status.responses",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "responses",
            ["sourceId"] = "question.relationship_status.responses",
            ["sourcePath"] = "dialogue/question_relationship_status/question_relationship_status.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/QuestionRelationshipStatus",
        ["namespace"] = "question.relationship_status",
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
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterCompliment",
                        ["text"] = {
                            ["EN"] = "That's kind of you to ask. I don't have a clear answer right now.",
                            ["TL"] = "Mabait mong itanong iyan. Wala pa akong malinaw na sagot sa ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentAlt",
                        ["text"] = {
                            ["EN"] = "Thanks for saying that. I can't give you a clear answer about relationships right now.",
                            ["TL"] = "Salamat sa sinabi mo. Hindi ko pa masagot nang malinaw ang tungkol sa relasyon ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentCommitted",
                        ["text"] = {
                            ["EN"] = "Thanks for the compliment, but I thought we were already together.",
                            ["TL"] = "Salamat sa papuri, pero akala ko tayo na.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusAfterComplimentWithdrawn",
                        ["text"] = {
                            ["EN"] = "Thanks, but I'd rather keep that personal.",
                            ["TL"] = "Salamat, pero mas gusto kong sarilinin muna iyan.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusCommitted",
                        ["text"] = {
                            ["EN"] = "I thought we were already together.",
                            ["TL"] = "Akala ko tayo na.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusUncertain",
                        ["text"] = {
                            ["EN"] = "I haven't really thought about dating. Right now, I'm focused on surviving.",
                            ["TL"] = "Hindi ko pa talaga naiisip ang makipag-date. Mas iniisip ko muna kung paano makakaligtas.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusUncertainAlt",
                        ["text"] = {
                            ["EN"] = "Honestly, I haven't had much room to think about relationships lately.",
                            ["TL"] = "Sa totoo lang, wala akong gaanong panahon para isipin ang tungkol sa relasyon ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_QuestionRelationshipStatusWithdrawn",
                        ["text"] = {
                            ["EN"] = "I'd rather not get into that. There's too much going on right now.",
                            ["TL"] = "Mas gusto kong huwag munang pag-usapan iyan. Marami pa tayong pinagdaraanan ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_RelationshipStatusAcknowledged",
                        ["text"] = {
                            ["EN"] = "Thanks for understanding. It's hard to think about relationships with everything going on.",
                            ["TL"] = "Salamat sa pag-unawa. Mahirap isipin ang relasyon sa dami ng nangyayari ngayon.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_RelationshipStatusAcknowledgedAlt",
                        ["text"] = {
                            ["EN"] = "I appreciate you listening. It's hard to make plans while we're trying to survive.",
                            ["TL"] = "Salamat sa pakikinig. Mahirap magplano habang sinusubukan nating mabuhay.",
                        },
                    },
                    {
                        ["key"] = "UI_PNC_Conversation_Semantic_RelationshipStatusAcknowledgedWithdrawn",
                        ["text"] = {
                            ["EN"] = "Thanks. I'd rather leave it there for now.",
                            ["TL"] = "Salamat. Mas gusto kong hanggang dito na lang muna.",
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
                                        "That's kind of you to ask. I don't have a clear answer right now.",
                                    },
                                    ["TL"] = {
                                        "Mabait mong itanong iyan. Wala pa akong malinaw na sagot sa ngayon.",
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
            ["responsePlanID"] = "question.relationship_status.responses",
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
                            ["fallback"] = "That's kind of you to ask. I don't have a clear answer right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.relationship_status.responses.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/question_relationship_status/question_relationship_status.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's kind of you to ask. I don't have a clear answer right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.relationship_status.responses.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That's kind of you to ask. I don't have a clear answer right now.",
                    },
                    ["TL"] = {
                        "Mabait mong itanong iyan. Wala pa akong malinaw na sagot sa ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
