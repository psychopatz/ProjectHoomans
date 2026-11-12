-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "navigation",
        ["id"] = "semantic.navigation.orders.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.navigation.orders.guarded",
            ["sourcePath"] = "psdl/dialogue/navigation.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_navigation_orders_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "NAVIGATION_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.orders.guarded.01",
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
                            ["textKey"] = "semantic.navigation.orders.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What order? Keep it realistic.",
                            },
                            ["TL"] = {
                                "Anong utos? Siguraduhing makatwiran.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.orders.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What do you want me to do? Nothing reckless.",
                            },
                            ["TL"] = {
                                "Ano'ng gusto mong gawin ko? Huwag mapusok.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.orders.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Give the order, but watch my back.",
                            },
                            ["TL"] = {
                                "Ibigay ang utos, pero bantayan mo likod ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.orders.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What's the directive? Make it sensible.",
                            },
                            ["TL"] = {
                                "Ano'ng direktiba? Gawing may kabuluhan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.orders.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm listening to commands, but I judge safety.",
                            },
                            ["TL"] = {
                                "Nakikinig ako sa utos, pero ako ang humahatol sa kaligtasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.orders.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What do you need done? Don't waste my time.",
                            },
                            ["TL"] = {
                                "Ano'ng kailangang gawin? Huwag sayangin ang oras ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.orders.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "State the command quickly.",
                            },
                            ["TL"] = {
                                "Sabihin ang utos agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.orders.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What's the plan? Don't get us trapped.",
                            },
                            ["TL"] = {
                                "Ano'ng plano? Huwag tayong ipitin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.navigation.orders.guarded.10",
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
