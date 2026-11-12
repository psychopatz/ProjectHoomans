-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_apology",
        ["id"] = "semantic.social.apology.friendly.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.apology.friendly.neutral",
            ["sourcePath"] = "psdl/dialogue/social_apology.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_apology_friendly_neutral",
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
                ["responseTemplateID"] = "semantic.social.apology.friendly",
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
                            ["textKey"] = "semantic.social.apology.friendly.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's okay. We can put that behind us.",
                            },
                            ["TL"] = {
                                "Ayos lang. Kalimutan na natin iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.friendly.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No worries. It happens to everyone.",
                            },
                            ["TL"] = {
                                "Huwag kang mag-alala. Nangyayari 'yan kahit kanino.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.friendly.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We're good. Don't worry about it.",
                            },
                            ["TL"] = {
                                "Ayos tayo. Huwag mo nang alalahanin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.friendly.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Forget about it. All good here.",
                            },
                            ["TL"] = {
                                "Kalimutan mo na. Ayos ang lahat dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.friendly.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's all right. We move forward.",
                            },
                            ["TL"] = {
                                "Ayos lang. Tuloy ang lakad natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.friendly.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No harm done. We're square.",
                            },
                            ["TL"] = {
                                "Walang nasaktan. Kuwits na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.friendly.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I appreciate the apology. We're good.",
                            },
                            ["TL"] = {
                                "Salamat sa paumanhin. Ayos na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.friendly.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't sweat the small stuff out here.",
                            },
                            ["TL"] = {
                                "Huwag mong problemahin ang maliliit na bagay dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.friendly.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We all have off moments. It's behind us.",
                            },
                            ["TL"] = {
                                "Lahat naman may pagkakamali. Lumipas na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.friendly.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All cleared up. Let's keep working.",
                            },
                            ["TL"] = {
                                "Malinaw na ang lahat. Tuloy na sa trabaho.",
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
