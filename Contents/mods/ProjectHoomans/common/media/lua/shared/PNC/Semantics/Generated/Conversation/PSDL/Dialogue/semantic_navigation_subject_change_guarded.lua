-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "navigation",
        ["id"] = "semantic.navigation.subject_change.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.navigation.subject_change.guarded",
            ["sourcePath"] = "psdl/dialogue/navigation.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_navigation_subject_change_guarded",
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
                ["category"] = "projecthoomans:navigation",
                ["responseTemplateID"] = "semantic.navigation.subject_change",
                ["sourceSurface"] = "content/navigation.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "NAVIGATION_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.subject_change.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All right. What is it?",
                            },
                            ["TL"] = {
                                "Sige. Ano iyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.subject_change.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Changing topics? Fine, make it quick.",
                            },
                            ["TL"] = {
                                "Ibang usapan? Sige, bilisan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.subject_change.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What else do you want to bring up?",
                            },
                            ["TL"] = {
                                "Ano pa ang gusto mong banggitin?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.subject_change.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Switching subjects. What now?",
                            },
                            ["TL"] = {
                                "Lilipat ng paksa. Ano ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.subject_change.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Go ahead, but keep your head on a swivel.",
                            },
                            ["TL"] = {
                                "Sige lang, pero patuloy na magmatyag.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.subject_change.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Different topic? Keep it relevant to surviving.",
                            },
                            ["TL"] = {
                                "Ibang paksa? Siguraduhing may kinalaman sa kaligtasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.subject_change.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What else? We don't have all day.",
                            },
                            ["TL"] = {
                                "Ano pa? Wala tayong buong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.subject_change.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Say what you need to say.",
                            },
                            ["TL"] = {
                                "Sabihin mo ang dapat mong sabihin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.subject_change.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "New subject? What is it?",
                            },
                            ["TL"] = {
                                "Bagong usapan? Ano 'yon?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.subject_change.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Listening, but don't waste time.",
                            },
                            ["TL"] = {
                                "Nakikinig ako, pero huwag mag-aksaya ng oras.",
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
        ["sourceShard"] = "psdl/dialogue/navigation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
