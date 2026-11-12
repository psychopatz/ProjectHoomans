-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.order_rejected.1",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.order_rejected.1",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_order_rejected_1",
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
                ["responseTemplateID"] = "semantic.tool_reply.order_rejected.1",
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
                                "I cannot do that right now.",
                            },
                            ["TL"] = {
                                "Hindi ko magagawa iyon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's not something I can pull off here.",
                            },
                            ["TL"] = {
                                "Hindi ko magagawa 'yan dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to execute that request at this time.",
                            },
                            ["TL"] = {
                                "Di maisakatuparan ang hiling na 'yan sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I have to decline that order.",
                            },
                            ["TL"] = {
                                "Kailangan kong tanggihan ang utos na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Not possible under current circumstances.",
                            },
                            ["TL"] = {
                                "Hindi posible sa kasalukuyang kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I can't carry that out right now.",
                            },
                            ["TL"] = {
                                "Di ko kayang isakatuparan 'yan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to comply with that command.",
                            },
                            ["TL"] = {
                                "Di makasusunod sa utos na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I can't do that. Find another solution.",
                            },
                            ["TL"] = {
                                "Di ko magagawa 'yan. Humanap ng ibang solusyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Order declined. Conditions won't allow it.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang utos. Di pinapayagan ng sitwasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I cannot perform that action right now.",
                            },
                            ["TL"] = {
                                "Hindi ko maisasagawa ang kilos na 'yan sa ngayon.",
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
