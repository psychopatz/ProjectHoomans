-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.order_camp.3",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.order_camp.3",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_order_camp_3",
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
                ["responseTemplateID"] = "semantic.tool_reply.order_camp.3",
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
                                "Understood. I will stay here and take care of my needs.",
                            },
                            ["TL"] = {
                                "Naintindihan. Mananatili ako rito at aasikasuhin ang mga pangangailangan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'll tend to my wounds and rest up here.",
                            },
                            ["TL"] = {
                                "Gagamutin ko ang mga sugat at magpapahinga rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Taking care of hunger and thirst in camp.",
                            },
                            ["TL"] = {
                                "Aasikasuhin ang gutom at uhaw sa kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll patch up my gear and eat a meal here.",
                            },
                            ["TL"] = {
                                "Aayusin ko ang gamit at kakain dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Good. I needed time to sort myself out.",
                            },
                            ["TL"] = {
                                "Mabuti. Kailangan ko ng oras para ayusin ang sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Handling my personal upkeep while we camp.",
                            },
                            ["TL"] = {
                                "Aasikasuhin ang pansariling kalagayan habang nagkakampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Resting, eating, and recovering strength.",
                            },
                            ["TL"] = {
                                "Nagpapahinga, kumakain, at nagpapalakas muli.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll use this camp time to recover.",
                            },
                            ["TL"] = {
                                "Gagamitin ko ang oras sa kampo para magpagaling.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Taking care of myself while holding camp.",
                            },
                            ["TL"] = {
                                "Aalagaan ang sarili habang nagbabantay sa kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Time for self-maintenance.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Oras na para mag-ayos ng katawan.",
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
