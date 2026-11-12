-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.wait_at.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.wait_at.active",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[35]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_wait_at_active",
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
                ["responseTemplateID"] = "semantic.task.wait_at.active",
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
                                "Waiting here now.",
                            },
                            ["TL"] = {
                                "Naghihintay na ako rito ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Currently holding position and waiting.",
                            },
                            ["TL"] = {
                                "Kasalukuyang nakapwesto at naghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Standing by at the designated spot.",
                            },
                            ["TL"] = {
                                "Nakahanda sa itinalagang pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Waiting at this location as ordered.",
                            },
                            ["TL"] = {
                                "Naghihintay sa lugar na ito ayon sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping watch while waiting right here.",
                            },
                            ["TL"] = {
                                "Nagbabantay habang naghihintay dito mismo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Holding at the marker.",
                            },
                            ["TL"] = {
                                "Hawak ang pwesto sa marka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Waiting quietly. Eyes open.",
                            },
                            ["TL"] = {
                                "Naghihintay nang tahimik. Bukas ang mga mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "In position and waiting.",
                            },
                            ["TL"] = {
                                "Nasa pwesto at naghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Stationary at the post.",
                            },
                            ["TL"] = {
                                "Nakatigil sa posteng ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Waiting here. Take your time.",
                            },
                            ["TL"] = {
                                "Naghihintay rito. Huwag magmadali.",
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
