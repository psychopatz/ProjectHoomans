-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "navigation",
        ["id"] = "semantic.navigation.orders.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.navigation.orders.terse",
            ["sourcePath"] = "psdl/dialogue/navigation.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_navigation_orders_terse",
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
                ["responseTemplateID"] = "semantic.navigation.orders",
                ["sourceSurface"] = "content/navigation.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "NAVIGATION_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.navigation.orders.terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What do you need?",
                            },
                            ["TL"] = {
                                "Ano ang kailangan mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.navigation.orders.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Orders?",
                            },
                            ["TL"] = {
                                "Mga utos?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.navigation.orders.terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Command?",
                            },
                            ["TL"] = {
                                "Utos?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.navigation.orders.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Directive?",
                            },
                            ["TL"] = {
                                "Tagubilin?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.navigation.orders.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What's next?",
                            },
                            ["TL"] = {
                                "Ano'ng susunod?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.navigation.orders.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Task?",
                            },
                            ["TL"] = {
                                "Gawain?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.navigation.orders.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Say the word.",
                            },
                            ["TL"] = {
                                "Sabihin mo lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.navigation.orders.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What now?",
                            },
                            ["TL"] = {
                                "Ano ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.navigation.orders.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Instructions?",
                            },
                            ["TL"] = {
                                "Mga bilin?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.navigation.orders.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Give order.",
                            },
                            ["TL"] = {
                                "Mag-utos ka.",
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
