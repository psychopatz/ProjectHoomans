-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.consume.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.consume.failed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_consume_failed",
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
                ["responseTemplateID"] = "semantic.task.consume.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/consume.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't use that.",
                            },
                            ["TL"] = {
                                "Hindi ko nagamit iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to consume that item.",
                            },
                            ["TL"] = {
                                "Bigo sa paggamit ng bagay na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Something interrupted me while trying to use that.",
                            },
                            ["TL"] = {
                                "May umabala sa akin habang sinusubukang gamitin iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't finish using it.",
                            },
                            ["TL"] = {
                                "Di natapos gamitin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to apply that right now.",
                            },
                            ["TL"] = {
                                "Di mailapat iyan sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Using that failed. Something went wrong.",
                            },
                            ["TL"] = {
                                "Pumalpak ang paggamit. May nangyaring mali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I lost hold of it or couldn't use it.",
                            },
                            ["TL"] = {
                                "Nabitawan ko o di nagamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't consume it. Area wasn't secure.",
                            },
                            ["TL"] = {
                                "Di nagamit. Di ligtas ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Action interrupted. Item not consumed.",
                            },
                            ["TL"] = {
                                "Naabala ang kilos. Di nagamit ang bagay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to take that.",
                            },
                            ["TL"] = {
                                "Bigo sa paggamit niyan.",
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
