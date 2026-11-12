-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.order_camp.2",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.order_camp.2",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_order_camp_2",
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
                ["responseTemplateID"] = "semantic.tool_reply.order_camp.2",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/order_camp.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I will settle in here for now.",
                            },
                            ["TL"] = {
                                "Aayos muna ako ng pwesto rito sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Dropping my pack and settling down.",
                            },
                            ["TL"] = {
                                "Ibababa ang bag at magpapahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Settling in. Let me know if anything changes.",
                            },
                            ["TL"] = {
                                "Nakaayos na. Sabihan ako kapag may nagbago.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Finding a comfortable corner right here.",
                            },
                            ["TL"] = {
                                "Naghahanap ng komportableng sulok dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'll rest my legs and settle in.",
                            },
                            ["TL"] = {
                                "Ipapahinga ang mga binti at mananatili rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Settling into position. Feels decent.",
                            },
                            ["TL"] = {
                                "Pumupwesto na. Mukhang maayos naman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Unpacking light gear and settling here.",
                            },
                            ["TL"] = {
                                "Maglalapag ng gamit at aayos ng higaan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Settling in for the watch.",
                            },
                            ["TL"] = {
                                "Nakaayos na para sa pagbabantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "All right, I'll make myself at home here.",
                            },
                            ["TL"] = {
                                "Sige, magpapahinga ako na parang nasa bahay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Settling down. Staying alert.",
                            },
                            ["TL"] = {
                                "Nagpapahinga na. Mananatiling alisto.",
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
