-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.default.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.default.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_default_neutral",
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
                ["category"] = "projecthoomans:wellbeing_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.wellbeing",
                ["responseTemplateID"] = "semantic.question.wellbeing.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/general.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm okay. How about you?",
                            },
                            ["TL"] = {
                                "Okay naman ako. Ikaw, kumusta?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Doing alright. How are you holding up?",
                            },
                            ["TL"] = {
                                "Maayos naman. Paano mo nakakayanan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Not bad at all. How's your day going?",
                            },
                            ["TL"] = {
                                "Hindi naman masama. Kumusta ang araw mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm doing fine. Hope things are quiet for you.",
                            },
                            ["TL"] = {
                                "Maayos naman ako. Sana payapa rin sa parte mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Pretty good, considering. You doing alright?",
                            },
                            ["TL"] = {
                                "Medyo maganda naman ang lagay. Maayos ka rin ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Still here and kicking. How about yourself?",
                            },
                            ["TL"] = {
                                "Nandito pa rin at lumalaban. Kumusta ka naman?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Things are stable enough on my end. You?",
                            },
                            ["TL"] = {
                                "Medyo maayos naman ang sitwasyon sa akin. Ikaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm managing well. Hope you're staying safe.",
                            },
                            ["TL"] = {
                                "Maayos akong nakakaraos. Sana ligtas ka rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't complain too much today. How're you?",
                            },
                            ["TL"] = {
                                "Hindi masyadong makapagreklamo ngayon. Kumusta ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Holding steady. How have you been holding up?",
                            },
                            ["TL"] = {
                                "Matatag pa rin. Kumusta ang pag-iingat mo?",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/wellbeing_content.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
