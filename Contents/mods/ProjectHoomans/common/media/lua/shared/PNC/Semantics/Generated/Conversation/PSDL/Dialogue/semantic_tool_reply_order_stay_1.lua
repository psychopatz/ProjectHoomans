-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.order_stay.1",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.order_stay.1",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_order_stay_1",
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
                ["responseTemplateID"] = "semantic.tool_reply.order_stay.1",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/order_stay.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right. I will hold here.",
                            },
                            ["TL"] = {
                                "Sige. Hahawakan ko ang pwesto rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Holding position right here.",
                            },
                            ["TL"] = {
                                "Hawak ko ang pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Guarding this spot.",
                            },
                            ["TL"] = {
                                "Naintindihan. Babantayan ang pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I will remain right where I am.",
                            },
                            ["TL"] = {
                                "Mananatili ako kung nasaan ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Holding ground as ordered.",
                            },
                            ["TL"] = {
                                "Hawak ang lupa ayon sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I won't move an inch.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Di ako aalis kahit isang pulgada.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Standing watch right here.",
                            },
                            ["TL"] = {
                                "Nakatayong bantay dito mismo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll keep this position secure.",
                            },
                            ["TL"] = {
                                "Pananatilihing ligtas ang posisyong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Holding here. Watch yourself out there.",
                            },
                            ["TL"] = {
                                "Dito lang ako. Mag-ingat ka sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stay order confirmed. Holding ground.",
                            },
                            ["TL"] = {
                                "Kumpirmadong utos na manatili. Hawak ang lupa.",
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
