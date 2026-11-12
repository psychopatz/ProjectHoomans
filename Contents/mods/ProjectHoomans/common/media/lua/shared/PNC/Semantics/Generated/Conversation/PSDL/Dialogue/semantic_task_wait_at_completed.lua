-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.wait_at.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.wait_at.completed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[37]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_wait_at_completed",
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
                ["responseTemplateID"] = "semantic.task.wait_at.completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/wait_at.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Finished waiting.",
                            },
                            ["TL"] = {
                                "Tapos na ang paghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Done waiting. What's the next move?",
                            },
                            ["TL"] = {
                                "Tapos nang maghintay. Ano ang susunod na galaw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Wait time concluded. Ready for orders.",
                            },
                            ["TL"] = {
                                "Tapos na ang oras ng paghihintay. Handa sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Held the spot. Standing down now.",
                            },
                            ["TL"] = {
                                "Nahawakan ang pwesto. Uurong na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Waiting task complete.",
                            },
                            ["TL"] = {
                                "Tapos na ang gawaing maghintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Done holding this ground.",
                            },
                            ["TL"] = {
                                "Tapos na sa paghawak ng lupang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Time is up. Finished waiting here.",
                            },
                            ["TL"] = {
                                "Tapos na ang oras. Tapos nang maghintay dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Rejoining you. Wait is over.",
                            },
                            ["TL"] = {
                                "Sasama muli sa 'yo. Tapos na ang paghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Held the post as long as needed.",
                            },
                            ["TL"] = {
                                "Nabantayan ang poste hangga't kinakailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Completed the wait order.",
                            },
                            ["TL"] = {
                                "Natapos ang utos na maghintay.",
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
