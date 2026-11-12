-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "navigation",
        ["id"] = "semantic.navigation.default.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.navigation.default.guarded",
            ["sourcePath"] = "psdl/dialogue/navigation.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_navigation_default_guarded",
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
                ["responseTemplateID"] = "semantic.navigation.default",
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
                            ["textKey"] = "semantic.navigation.default.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All right. What now?",
                            },
                            ["TL"] = {
                                "Sige. Ano ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.default.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What is it? Keep it short.",
                            },
                            ["TL"] = {
                                "Ano 'yon? Iklian mo lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.default.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Make it quick. We're exposed.",
                            },
                            ["TL"] = {
                                "Bilisan mo. Lantad tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.default.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What do you want? Eyes open.",
                            },
                            ["TL"] = {
                                "Ano'ng kailangan mo? Buksan ang mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.default.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Speak up, but don't draw attention.",
                            },
                            ["TL"] = {
                                "Magsalita ka, pero huwag kang mag-ingay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.default.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What's on your mind? Watch the street.",
                            },
                            ["TL"] = {
                                "Ano'ng iniisip mo? Bantayan ang kalsada.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.default.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What now? We can't linger here.",
                            },
                            ["TL"] = {
                                "Ano ngayon? Hindi tayo pwedeng tumambay rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.default.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm listening, but keep scanning.",
                            },
                            ["TL"] = {
                                "Nakikinig ako, pero patuloy na magmasid.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.default.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "State your business quickly.",
                            },
                            ["TL"] = {
                                "Sabihin mo agad ang kailangan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.default.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What is it? Trouble?",
                            },
                            ["TL"] = {
                                "Ano 'yon? May gulo ba?",
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
