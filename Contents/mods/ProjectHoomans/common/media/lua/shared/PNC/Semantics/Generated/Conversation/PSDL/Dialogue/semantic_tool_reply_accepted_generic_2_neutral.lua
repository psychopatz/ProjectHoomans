-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["id"] = "semantic.tool_reply.accepted_generic.2.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.accepted_generic.2.neutral",
            ["sourcePath"] = "psdl/dialogue/social_tool_replies_affirmation.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_accepted_generic_2_neutral",
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
                ["responseTemplateID"] = "semantic.tool_reply.accepted_generic.2",
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
                                "I will keep that in mind.",
                            },
                            ["TL"] = {
                                "Isasaisip ko iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I will remember that.",
                            },
                            ["TL"] = {
                                "Tandaan ko iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Good to know. I will think about it.",
                            },
                            ["TL"] = {
                                "Mabuting malaman. Pag-iisipan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I will note that down in my head.",
                            },
                            ["TL"] = {
                                "Itatatak ko 'yan sa isip ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for telling me. I will keep it in mind.",
                            },
                            ["TL"] = {
                                "Salamat sa pagsabi. Tatandaan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I will hold onto that thought.",
                            },
                            ["TL"] = {
                                "Isasapuso at isasaisip ko iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I will factor that in.",
                            },
                            ["TL"] = {
                                "Isasaalang-alang ko 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Duly noted.",
                            },
                            ["TL"] = {
                                "Tala ko na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I will be mindful of that.",
                            },
                            ["TL"] = {
                                "Magiging maingat ako tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Right. I will keep that in mind moving forward.",
                            },
                            ["TL"] = {
                                "Sige. Tatandaan ko 'yan sa mga susunod.",
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
