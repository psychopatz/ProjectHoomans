-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_apology",
        ["id"] = "semantic.social.apology.default.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.apology.default.terse",
            ["sourcePath"] = "psdl/dialogue/social_apology.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_apology_default_terse",
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
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "APOLOGY_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.default.terse.01",
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
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.default.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Why?",
                            },
                            ["TL"] = {
                                "Bakit?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.default.terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "For what?",
                            },
                            ["TL"] = {
                                "Dahil saan?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.default.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What did you break?",
                            },
                            ["TL"] = {
                                "Anong sinira mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.default.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Explain.",
                            },
                            ["TL"] = {
                                "Ipaliwanag mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.default.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What happened?",
                            },
                            ["TL"] = {
                                "Anong nangyari?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.default.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Apologizing for what?",
                            },
                            ["TL"] = {
                                "Hihingi ng tawad para saan?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.default.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Spit it out.",
                            },
                            ["TL"] = {
                                "Diretsuhin mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.default.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Why are you sorry?",
                            },
                            ["TL"] = {
                                "Bakit ka nagso-sorry?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.social.apology.default.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What did you do now?",
                            },
                            ["TL"] = {
                                "Anong ginawa mo ngayon?",
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
