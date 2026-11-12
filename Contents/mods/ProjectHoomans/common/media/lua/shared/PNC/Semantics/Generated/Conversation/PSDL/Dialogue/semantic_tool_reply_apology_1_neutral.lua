-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["id"] = "semantic.tool_reply.apology.1.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.apology.1.neutral",
            ["sourcePath"] = "psdl/dialogue/social_tool_replies_affirmation.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_apology_1_neutral",
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
                ["responseTemplateID"] = "semantic.tool_reply.apology.1",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/tool_replies/apology.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Let us move on.",
                            },
                            ["TL"] = {
                                "Sige. Magpatuloy na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "No problem. Let us keep moving.",
                            },
                            ["TL"] = {
                                "Walang anuman. Tuloy na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "We are good. Let us get back to business.",
                            },
                            ["TL"] = {
                                "Ayos na tayo. Balik na tayo sa ginagawa natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Done. No need to dwell on it.",
                            },
                            ["TL"] = {
                                "Tapos na 'yon. Hindi na kailangang pag-usapan pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Water under the bridge.",
                            },
                            ["TL"] = {
                                "Sige. Lumipas na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Let us put it behind us and focus on surviving.",
                            },
                            ["TL"] = {
                                "Iwan na natin 'yan sa likod at magpokus sa kaligtasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Fine by me. Move forward.",
                            },
                            ["TL"] = {
                                "Ayos lang sa 'kin. Abante na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Okay. We move past it.",
                            },
                            ["TL"] = {
                                "Sige. Kalimutan na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Agreed. Let us not waste daylight on it.",
                            },
                            ["TL"] = {
                                "Sang-ayon ako. Huwag nating sayangin ang oras diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. We are square.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Kuwits na tayo.",
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
        ["sourceShard"] = "psdl/dialogue/social_tool_replies_affirmation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
