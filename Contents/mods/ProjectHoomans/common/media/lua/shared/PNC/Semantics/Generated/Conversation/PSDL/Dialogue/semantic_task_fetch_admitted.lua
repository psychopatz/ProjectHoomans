-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.fetch.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.fetch.admitted",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_fetch_admitted",
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
                ["responseTemplateID"] = "semantic.task.fetch.admitted",
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
                                "I'll fetch that.",
                            },
                            ["TL"] = {
                                "Kukunin ko iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I will retrieve the item.",
                            },
                            ["TL"] = {
                                "Naintindihan. Kukunin ko ang gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll go grab that for you.",
                            },
                            ["TL"] = {
                                "Pupuntahan ko para kunin 'yan para sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "On it. Fetching the supplies.",
                            },
                            ["TL"] = {
                                "Inaasikaso na. Kukunin ang mga kagamitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Right away. Going to pick it up.",
                            },
                            ["TL"] = {
                                "Agad-agad. Pupulutin ko 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll bring it back.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Ibabalik ko rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'll secure that item.",
                            },
                            ["TL"] = {
                                "Kukunin ko ang gamit na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Heading out to fetch it.",
                            },
                            ["TL"] = {
                                "Lalabas para kunin iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got the order. Fetching.",
                            },
                            ["TL"] = {
                                "Nakuha ang utos. Kukunin na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds good. Retrieving it now.",
                            },
                            ["TL"] = {
                                "Maganda 'yan. Kukunin na ngayon.",
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
