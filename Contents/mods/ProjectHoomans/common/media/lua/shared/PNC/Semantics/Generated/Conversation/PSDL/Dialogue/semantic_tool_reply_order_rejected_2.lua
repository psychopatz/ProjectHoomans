-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.order_rejected.2",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.order_rejected.2",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_order_rejected_2",
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
                ["responseTemplateID"] = "semantic.tool_reply.order_rejected.2",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/order_rejected.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That order is not going to work.",
                            },
                            ["TL"] = {
                                "Hindi uubra ang utos na iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's a bad plan and it won't succeed.",
                            },
                            ["TL"] = {
                                "Masamang plano 'yan at hindi magtatagumpay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That order makes no sense in this situation.",
                            },
                            ["TL"] = {
                                "Walang saysay ang utos na 'yan sa sitwasyong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "That won't work. We need a different approach.",
                            },
                            ["TL"] = {
                                "Hindi uubra 'yan. Kailangan natin ng ibang diskarte.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not following an order that leads to failure.",
                            },
                            ["TL"] = {
                                "Di ako susunod sa utos na papunta sa kapahamakan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "That command will only get us killed.",
                            },
                            ["TL"] = {
                                "Ipapahamak lang tayo ng utos na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Not going to work out. Try another idea.",
                            },
                            ["TL"] = {
                                "Hindi magiging maayos 'yan. Sumubok ng ibang ideya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Flawed order. I won't execute it.",
                            },
                            ["TL"] = {
                                "May depekto ang utos. Di ko isasakatuparan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "That plan is dead in the water.",
                            },
                            ["TL"] = {
                                "Patay ang planong 'yan sa simula pa lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "That won't work out here. Give a better order.",
                            },
                            ["TL"] = {
                                "Di uubra 'yan dito. Magbigay ka ng mas maayos na utos.",
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
