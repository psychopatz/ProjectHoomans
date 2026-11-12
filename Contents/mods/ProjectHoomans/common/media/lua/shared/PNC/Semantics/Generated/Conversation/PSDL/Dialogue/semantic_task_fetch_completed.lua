-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.fetch.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.fetch.completed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_fetch_completed",
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
                ["category"] = "projecthoomans:task_lifecycle",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.task.fetch.completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Here you go.",
                            },
                            ["TL"] = {
                                "Heto na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Retrieved the item. Here it is.",
                            },
                            ["TL"] = {
                                "Nakuha na ang gamit. Heto na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Got what you asked for.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang hiningi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Fetched and delivered.",
                            },
                            ["TL"] = {
                                "Nakuha at naihatid na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Here are the goods.",
                            },
                            ["TL"] = {
                                "Heto ang mga kagamitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Task completed. Item secured.",
                            },
                            ["TL"] = {
                                "Tapos na ang gawain. Nakuha ang gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "All fetched. Safe in hand.",
                            },
                            ["TL"] = {
                                "Nakuha na lahat. Hawak ko na nang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Here it is. One piece.",
                            },
                            ["TL"] = {
                                "Heto na. Buo pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Delivery made. What's next?",
                            },
                            ["TL"] = {
                                "Naihatid na. Ano ang susunod?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Retrieved as requested.",
                            },
                            ["TL"] = {
                                "Nakuha ayon sa hiling.",
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
        ["sourceShard"] = "psdl/dialogue/task_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
