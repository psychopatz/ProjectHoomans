-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_apology",
        ["id"] = "semantic.social.apology.withdrawn.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.apology.withdrawn.neutral",
            ["sourcePath"] = "psdl/dialogue/social_apology.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_apology_withdrawn_neutral",
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
                ["responseTemplateID"] = "semantic.social.apology.withdrawn",
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
                            ["textKey"] = "semantic.social.apology.withdrawn.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All right. Let's leave it there.",
                            },
                            ["TL"] = {
                                "Sige. Tama na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.withdrawn.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Okay. Let's drop the subject.",
                            },
                            ["TL"] = {
                                "Sige. Huwag na nating pag-usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.withdrawn.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Moving past it.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Lumalampas na roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.withdrawn.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No need to say more. It's settled.",
                            },
                            ["TL"] = {
                                "Wala nang dapat sabihin pa. Ayos na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.withdrawn.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We've said what we needed to say.",
                            },
                            ["TL"] = {
                                "Nasabi na natin ang kailangang sabihin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.withdrawn.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let's leave it at that and get back to work.",
                            },
                            ["TL"] = {
                                "Iwan na natin doon at bumalik sa trabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.withdrawn.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fine by me. Subject closed.",
                            },
                            ["TL"] = {
                                "Ayos sa akin. Sarado na ang usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.withdrawn.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing more to discuss. Let's move.",
                            },
                            ["TL"] = {
                                "Wala nang dapat pagtalunan pa. Tara na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.withdrawn.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. We'll leave it alone.",
                            },
                            ["TL"] = {
                                "Makatwiran. Hayaan na natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.social.apology.withdrawn.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All right. That's the end of it.",
                            },
                            ["TL"] = {
                                "Sige. Diyan na nagtatapos 'yan.",
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
