-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_apology",
        ["id"] = "semantic.social.apology.default.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.apology.default.warm",
            ["sourcePath"] = "psdl/dialogue/social_apology.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_apology_default_warm",
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
                ["category"] = "projecthoomans:social.apology",
                ["responseTemplateID"] = "semantic.social.apology.default",
                ["sourceSurface"] = "content/social_apology.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "APOLOGY_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.default.warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What are you apologizing for?",
                            },
                            ["TL"] = {
                                "Ano ang hinihingi mo ng tawad?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.default.warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hey, you don't have to apologize to me.",
                            },
                            ["TL"] = {
                                "Huy, hindi mo kailangang humingi ng tawad sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.default.warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What's this for? We're good.",
                            },
                            ["TL"] = {
                                "Para saan ito? Ayos tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.default.warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't sweat it. What's on your mind?",
                            },
                            ["TL"] = {
                                "Huwag mong alalahanin. Anong iniisip mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.default.warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You didn't do anything wrong. What happened?",
                            },
                            ["TL"] = {
                                "Wala kang ginawang mali. Anong nangyari?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.default.warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You don't need to apologize. We look out for each other.",
                            },
                            ["TL"] = {
                                "Di mo kailangang magpaumanhin. Nagtutulungan tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.default.warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Why the apology? Everything is okay between us.",
                            },
                            ["TL"] = {
                                "Bakit ka nagpapaumanhin? Maayos ang lahat sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.default.warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You're too hard on yourself. What's wrong?",
                            },
                            ["TL"] = {
                                "Masyado mong pinahihirapan ang sarili mo. May problema ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.default.warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No need for apologies here. We're on the same side.",
                            },
                            ["TL"] = {
                                "Walang kailangang tawad dito. Magkakampi tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.social.apology.default.warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's all right. You really don't have to apologize.",
                            },
                            ["TL"] = {
                                "Ayos lang talaga. Hindi mo kailangang mag-sorry.",
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
        ["sourceShard"] = "psdl/dialogue/social_apology.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
