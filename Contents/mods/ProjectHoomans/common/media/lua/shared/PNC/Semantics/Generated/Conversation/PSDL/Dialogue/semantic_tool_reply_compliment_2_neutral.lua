-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["id"] = "semantic.tool_reply.compliment.2.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.compliment.2.neutral",
            ["sourcePath"] = "psdl/dialogue/social_tool_replies_affirmation.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_compliment_2_neutral",
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
                ["responseTemplateID"] = "semantic.tool_reply.compliment.2",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/tool_replies/compliment.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I appreciate the compliment.",
                            },
                            ["TL"] = {
                                "Salamat sa papuri.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for the compliment.",
                            },
                            ["TL"] = {
                                "Salamat sa magandang sinabi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I will take the compliment. Thank you.",
                            },
                            ["TL"] = {
                                "Tatanggapin ko ang papuri. Maraming salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Much obliged for the kind thought.",
                            },
                            ["TL"] = {
                                "Maraming salamat sa magandang kaisipan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. I work hard at what I do.",
                            },
                            ["TL"] = {
                                "Salamat. Pinagsisikapan ko talaga ang ginagawa ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "That is good feedback to hear.",
                            },
                            ["TL"] = {
                                "Magandang marinig ang ganitong puna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciated. I try to stay sharp.",
                            },
                            ["TL"] = {
                                "Salamat. Sinisikap kong manatiling alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you. It means something coming from you.",
                            },
                            ["TL"] = {
                                "Salamat. May halaga 'yan galing sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I am flattered. Thank you.",
                            },
                            ["TL"] = {
                                "Natutuwa ako sa sinabi mo. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. That boost is welcome.",
                            },
                            ["TL"] = {
                                "Salamat. Nakakapagpalakas ng loob 'yan.",
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
