-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.queued_sexual.1",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.queued_sexual.1",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[35]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_queued_sexual_1",
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
                ["category"] = "projecthoomans:tool_replies",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.tool_reply.queued_sexual.1",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/queued_sexual.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I heard you. Give me a second.",
                            },
                            ["TL"] = {
                                "Narinig kita. Bigyan mo ako ng sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Heard that proposition. Let me catch my breath.",
                            },
                            ["TL"] = {
                                "Narinig ang alok na 'yan. Huminga muna ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I heard you clearly. Hold on for a moment.",
                            },
                            ["TL"] = {
                                "Narinig kita nang malinaw. Maghintay nang sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Message received loud and clear. Give me a minute.",
                            },
                            ["TL"] = {
                                "Nakuha ang mensahe nang malinaw. Bigyan mo ako ng sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I heard that. Give me a beat to think.",
                            },
                            ["TL"] = {
                                "Narinig ko 'yon. Bigyan mo ako ng oras para mag-isip.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Heard. That's a lot to process right now.",
                            },
                            ["TL"] = {
                                "Narinig. Napakabigat iproseso niyan sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I heard what you just proposed. Just hold up.",
                            },
                            ["TL"] = {
                                "Narinig ko ang inalok mo. Teka lang muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Got that. Let me gather my thoughts.",
                            },
                            ["TL"] = {
                                "Nakuha 'yon. Tipunin ko muna ang isip ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I heard you. Don't rush me.",
                            },
                            ["TL"] = {
                                "Narinig kita. Huwag mo akong madaliin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Heard every word. Give me some room.",
                            },
                            ["TL"] = {
                                "Narinig ang bawat salita. Bigyan mo ako ng puwang.",
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
        ["sourceShard"] = "psdl/dialogue/task_tool_replies.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
