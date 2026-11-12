-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_acknowledged_neutral",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.social.acknowledged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/acknowledgement.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Understood.",
                            },
                            ["TL"] = {
                                "Sige. Naiintindihan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you. Makes sense.",
                            },
                            ["TL"] = {
                                "Narinig kita. May katuturan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. We can work with that.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Pwede nating gamitin 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Message received. Moving forward.",
                            },
                            ["TL"] = {
                                "Natanggap ang mensahe. Magpapatuloy na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds fair to me.",
                            },
                            ["TL"] = {
                                "Mukhang makatwiran para sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Point taken.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang punto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Let's proceed.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Magpatuloy na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "All right. We're on the same page.",
                            },
                            ["TL"] = {
                                "Sige. Pareho tayo ng takbo ng isip.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. Good to know.",
                            },
                            ["TL"] = {
                                "Makatwiran. Mabuting malaman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Acknowledged. Let's get it done.",
                            },
                            ["TL"] = {
                                "Kinikilala ko. Tapusin na natin.",
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
        ["sourceShard"] = "psdl/dialogue/social_reactions_ack_dispute.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
