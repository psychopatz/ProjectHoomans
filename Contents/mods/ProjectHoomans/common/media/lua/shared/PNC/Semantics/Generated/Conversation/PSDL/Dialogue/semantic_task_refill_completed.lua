-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.refill.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.refill.completed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[32]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_refill_completed",
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
                ["responseTemplateID"] = "semantic.task.refill.completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/refill.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All topped off. Container is full.",
                            },
                            ["TL"] = {
                                "Puno na lahat. Punong-puno ang lalagyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Refill complete. Ready for the road.",
                            },
                            ["TL"] = {
                                "Tapos na ang pagpuno. Handa na sa paglakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Finished refilling with clean water.",
                            },
                            ["TL"] = {
                                "Tapos nang lagyan ng malinis na tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Bottles are full again.",
                            },
                            ["TL"] = {
                                "Puno na muli ang mga bote.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Task done. Plenty of water now.",
                            },
                            ["TL"] = {
                                "Tapos na ang gawain. Marami nang tubig ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Refilled and secured.",
                            },
                            ["TL"] = {
                                "Napuno na at naselyuhan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Canteens are full. Good work.",
                            },
                            ["TL"] = {
                                "Puno na ang mga sisidlan. Magaling.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "All filled up.",
                            },
                            ["TL"] = {
                                "Puno na ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Water refilled successfully.",
                            },
                            ["TL"] = {
                                "Matagumpay na nalagyan ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Completed refilling the supply.",
                            },
                            ["TL"] = {
                                "Natapos ang pagpuno sa supply.",
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
