-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_apology",
        ["id"] = "semantic.social.apology.stressed.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.apology.stressed.neutral",
            ["sourcePath"] = "psdl/dialogue/social_apology.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_apology_stressed_neutral",
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
                ["responseTemplateID"] = "semantic.social.apology.stressed",
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
                            ["textKey"] = "semantic.social.apology.stressed.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know things are tense. Let's keep it calm.",
                            },
                            ["TL"] = {
                                "Alam kong tensiyonado tayo. Panatilihin nating mahinahon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.stressed.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We're all under a lot of stress. Just take a breath.",
                            },
                            ["TL"] = {
                                "Lahat tayo nai-stress. Huminga ka muna nang malalim.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.stressed.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Tensions are high right now. Let's not lose our heads.",
                            },
                            ["TL"] = {
                                "Mataas ang tensiyon ngayon. Huwag tayong mawalan ng katinuan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.stressed.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's fine. We just need to keep our cool.",
                            },
                            ["TL"] = {
                                "Ayos lang. Kailangan lang nating magpakahinahon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.stressed.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Pressure gets to everyone out here. We're okay.",
                            },
                            ["TL"] = {
                                "Lahat naman nadadala sa bigat ng sitwasyon. Ayos lang tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.stressed.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let's reset and focus on what needs doing.",
                            },
                            ["TL"] = {
                                "Mag-reset tayo at magpokus sa kailangang gawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.stressed.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No one's at their best under this much strain. It's fine.",
                            },
                            ["TL"] = {
                                "Walang perpekto kapag ganito kabigat ang sitwasyon. Ayos lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.stressed.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Take it easy. We can work through this.",
                            },
                            ["TL"] = {
                                "Dahan-dahan lang. Kakayanin natin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.stressed.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's all right. Let's keep our nerves steady.",
                            },
                            ["TL"] = {
                                "Ayos lang. Panatilihin nating kalmado ang sarili natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.stressed.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Let's de-escalate and move forward.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Magpahinga muna at magpatuloy.",
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
