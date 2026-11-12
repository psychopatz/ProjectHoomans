-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.eat.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.eat.failed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_eat_failed",
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
                ["responseTemplateID"] = "semantic.task.eat.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/eat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't eat that.",
                            },
                            ["TL"] = {
                                "Hindi ko nakain iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to eat. The food was rotten or spoiled.",
                            },
                            ["TL"] = {
                                "Bigo sa pagkain. Bulok o panis ang pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't eat that. It smelled dangerous.",
                            },
                            ["TL"] = {
                                "Di makain 'yon. Amoy delikado.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I was interrupted while trying to eat.",
                            },
                            ["TL"] = {
                                "Naabala ako habang sumusubok kumain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to eat right now. Area under threat.",
                            },
                            ["TL"] = {
                                "Di makakain ngayon. May banta sa lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Eating failed. Food was ruined.",
                            },
                            ["TL"] = {
                                "Pumalpak ang pagkain. Nasira ang pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't stomach that item.",
                            },
                            ["TL"] = {
                                "Di matunawan sa bagay na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Dropped or lost the food before eating.",
                            },
                            ["TL"] = {
                                "Nahulog o nawala ang pagkain bago nakain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Action failed. Still starving.",
                            },
                            ["TL"] = {
                                "Bigo ang kilos. Gutom pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to consume meal.",
                            },
                            ["TL"] = {
                                "Bigo sa pagtapos ng pagkain.",
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
