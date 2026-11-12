-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.rejected_generic.2",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.rejected_generic.2",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[40]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_rejected_generic_2",
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
                ["responseTemplateID"] = "semantic.tool_reply.rejected_generic.2",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/rejected_generic.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I am not taking that from you right now.",
                            },
                            ["TL"] = {
                                "Hindi ko tatanggapin iyan mula sa iyo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not in the mood for that kind of talk.",
                            },
                            ["TL"] = {
                                "Wala ako sa mood para sa ganyang usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm rejecting that completely.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ko 'yan nang buo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "You can keep that nonsense to yourself.",
                            },
                            ["TL"] = {
                                "Itago mo sa sarili mo ang kalokohang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not putting up with that today.",
                            },
                            ["TL"] = {
                                "Di ko pagtitiisan 'yan ngayong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Not taking that. Walk it back.",
                            },
                            ["TL"] = {
                                "Di tatanggapin 'yan. Bawiin mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I refuse to engage with that.",
                            },
                            ["TL"] = {
                                "Tumatanggi akong makipag-usap tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm shutting that down immediately.",
                            },
                            ["TL"] = {
                                "Papatayin ko agad ang usapang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Not tolerating that right now.",
                            },
                            ["TL"] = {
                                "Di ko palalampasin 'yan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not accepting that from you.",
                            },
                            ["TL"] = {
                                "Hindi ko tatanggapin 'yan galing sa 'yo.",
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
