-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_apology",
        ["id"] = "semantic.social.apology.default.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.apology.default.guarded",
            ["sourcePath"] = "psdl/dialogue/social_apology.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_apology_default_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "APOLOGY_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.default.guarded.01",
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
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.default.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Why are you apologizing? What happened?",
                            },
                            ["TL"] = {
                                "Bakit ka nagpapaumanhin? Anong nangyari?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.default.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What went wrong that I should know about?",
                            },
                            ["TL"] = {
                                "Anong pumalpak na dapat kong malaman?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.default.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "People only apologize when they messed up. What was it?",
                            },
                            ["TL"] = {
                                "Nagsasabi lang ng sorry ang tao kapag pumalpak. Ano 'yon?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.default.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What are you trying to get ahead of?",
                            },
                            ["TL"] = {
                                "Ano ang inuunahan mong sabihin?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.default.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Did you touch something you shouldn't have?",
                            },
                            ["TL"] = {
                                "May ginalaw ka ba na hindi dapat?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.default.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hold on. Why are you saying sorry to me?",
                            },
                            ["TL"] = {
                                "Teka. Bakit ka humihingi ng tawad sa akin?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.default.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "What's the damage?",
                            },
                            ["TL"] = {
                                "Gaano kalaki ang sira?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.default.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Tell me what you did before I find out myself.",
                            },
                            ["TL"] = {
                                "Sabihin mo ang ginawa mo bago ko pa matuklasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.social.apology.default.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't apologize until you tell me what you did.",
                            },
                            ["TL"] = {
                                "Huwag kang mag-sorry hangga't di mo sinasabi ang ginawa mo.",
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
