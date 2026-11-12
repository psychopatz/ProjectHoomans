-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_apology",
        ["id"] = "semantic.social.apology.default.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.apology.default.neutral",
            ["sourcePath"] = "psdl/dialogue/social_apology.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_apology_default_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "APOLOGY_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.default.neutral.01",
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
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.default.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What is that for?",
                            },
                            ["TL"] = {
                                "Para saan iyan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.default.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Why are you saying sorry?",
                            },
                            ["TL"] = {
                                "Bakit ka humihingi ng pasensya?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.default.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What did you do?",
                            },
                            ["TL"] = {
                                "Anong ginawa mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.default.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Did something happen that I missed?",
                            },
                            ["TL"] = {
                                "May nangyari ba na hindi ko napansin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.default.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No need to apologize unless something went wrong.",
                            },
                            ["TL"] = {
                                "Walang kailangang ihingi ng tawad maliban kung may nagkamali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.default.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What's the apology about?",
                            },
                            ["TL"] = {
                                "Tungkol saan ang paumanhin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.default.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You don't owe me an apology unless you broke something.",
                            },
                            ["TL"] = {
                                "Wala kang utang na tawad sa 'kin maliban kung may nasira ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.default.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hold on, what are you apologizing for?",
                            },
                            ["TL"] = {
                                "Teka, para saan ang tawad mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.default.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What brought this on?",
                            },
                            ["TL"] = {
                                "Bakit mo biglang sinabi 'yan?",
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
