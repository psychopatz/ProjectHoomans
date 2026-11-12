-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.order_generic.2",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.order_generic.2",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_order_generic_2",
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
                ["responseTemplateID"] = "semantic.tool_reply.order_generic.2",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/order_generic.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
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
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Order received loud and clear.",
                            },
                            ["TL"] = {
                                "Natanggap ang utos nang malakas at malinaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Moving on that now.",
                            },
                            ["TL"] = {
                                "Naintindihan. Kikilos na roon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Clear as crystal. Executing.",
                            },
                            ["TL"] = {
                                "Kasing-linaw ng kristal. Isasakatuparan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Message understood.",
                            },
                            ["TL"] = {
                                "Naiintindihan ang mensahe.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I will comply.",
                            },
                            ["TL"] = {
                                "Naintindihan. Susunod ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Orders clear. Starting now.",
                            },
                            ["TL"] = {
                                "Malinaw ang mga utos. Simulan na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. No problem.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Walang problema.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Clear. On my way to do it.",
                            },
                            ["TL"] = {
                                "Malinaw. Papunta na para gawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood completely.",
                            },
                            ["TL"] = {
                                "Lubos na naiintindihan.",
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
