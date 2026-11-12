-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["id"] = "semantic.tool_reply.accepted_generic.1.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.accepted_generic.1.neutral",
            ["sourcePath"] = "psdl/dialogue/social_tool_replies_affirmation.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_accepted_generic_1_neutral",
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
                ["responseTemplateID"] = "semantic.tool_reply.accepted_generic.1",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/tool_replies/accepted_generic.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you.",
                            },
                            ["TL"] = {
                                "Narinig kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Got it.",
                            },
                            ["TL"] = {
                                "Nakuha ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough.",
                            },
                            ["TL"] = {
                                "May punto ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I hear what you are saying.",
                            },
                            ["TL"] = {
                                "Naririnig ko ang sinasabi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Message received.",
                            },
                            ["TL"] = {
                                "Malinaw, nakuha ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Makes sense to me.",
                            },
                            ["TL"] = {
                                "May katuturan 'yan para sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
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
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I am listening.",
                            },
                            ["TL"] = {
                                "Nakikinig ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "All right. I hear you.",
                            },
                            ["TL"] = {
                                "Sige. Naririnig kita.",
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
