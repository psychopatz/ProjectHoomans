-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "navigation",
        ["id"] = "semantic.navigation.orders.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.navigation.orders.neutral",
            ["sourcePath"] = "psdl/dialogue/navigation.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_navigation_orders_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "NAVIGATION_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.navigation.orders.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All right. What do you need?",
                            },
                            ["TL"] = {
                                "Sige. Ano ang kailangan mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.navigation.orders.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What are your orders?",
                            },
                            ["TL"] = {
                                "Ano ang mga utos mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.navigation.orders.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm ready for instructions. What should I do?",
                            },
                            ["TL"] = {
                                "Handa na ako sa tagubilin. Ano'ng dapat kong gawin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.navigation.orders.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What do you need me to handle?",
                            },
                            ["TL"] = {
                                "Ano ang kailangan mong asikasuhin ko?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.navigation.orders.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Give me the task.",
                            },
                            ["TL"] = {
                                "Ibigay mo sa akin ang gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.navigation.orders.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What are our next steps?",
                            },
                            ["TL"] = {
                                "Ano ang susunod nating mga hakbang?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.navigation.orders.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Standing by for orders.",
                            },
                            ["TL"] = {
                                "Nakaabang sa mga utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.navigation.orders.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What would you like me to do next?",
                            },
                            ["TL"] = {
                                "Ano ang gusto mong gawin ko susunod?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.navigation.orders.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Tell me what needs doing.",
                            },
                            ["TL"] = {
                                "Sabihin mo kung ano ang kailangang gawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.navigation.orders.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Awaiting your directive.",
                            },
                            ["TL"] = {
                                "Naghihintay sa tagubilin mo.",
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
