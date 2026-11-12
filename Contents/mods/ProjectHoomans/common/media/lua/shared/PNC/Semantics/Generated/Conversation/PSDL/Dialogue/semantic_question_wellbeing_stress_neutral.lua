-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "wellbeing_content",
        ["id"] = "semantic.question.wellbeing.stress.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.wellbeing.stress.neutral",
            ["sourcePath"] = "psdl/dialogue/wellbeing_content.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_wellbeing_stress_neutral",
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
                ["responseTemplateID"] = "semantic.question.wellbeing.stress",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/wellbeing/emotional.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm tense, but I can keep going.",
                            },
                            ["TL"] = {
                                "Tensiyonado ako, pero kaya ko pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Nerves are frayed. The tension is getting to me.",
                            },
                            ["TL"] = {
                                "Naiipit ang mga nerbyos ko. Ramdam ko ang tensiyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Feeling the pressure constantly out here.",
                            },
                            ["TL"] = {
                                "Laging mabigat ang pakiramdam dito sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "On edge, jumping at every shadow.",
                            },
                            ["TL"] = {
                                "Kabado ako, nabibigla sa bawat anino.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Stress is wearing me down faster than the walking.",
                            },
                            ["TL"] = {
                                "Mas nakakapagod ang stress kaysa sa mismong paglalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hard to unwind when danger could be anywhere.",
                            },
                            ["TL"] = {
                                "Mahirap magrelaks kapag may panganib kahit saan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "My shoulders are tight as iron from all this stress.",
                            },
                            ["TL"] = {
                                "Mabigat ang mga balikat ko sa sobrang stress.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just trying to keep my sanity intact.",
                            },
                            ["TL"] = {
                                "Pinipilit ko lang mapanatili ang katinuan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Every little noise has me reaching for my weapon.",
                            },
                            ["TL"] = {
                                "Bawat kaluskos napapahawak ako agad sa armas ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "It's a lot to process, but I'm holding it in.",
                            },
                            ["TL"] = {
                                "Mabigat dalhin ang lahat, pero tinitiis ko.",
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
