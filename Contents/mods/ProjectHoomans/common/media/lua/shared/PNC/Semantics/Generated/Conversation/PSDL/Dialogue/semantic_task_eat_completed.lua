-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.eat.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.eat.completed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_eat_completed",
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
                ["responseTemplateID"] = "semantic.task.eat.completed",
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
                                "Finished eating. Feeling much better.",
                            },
                            ["TL"] = {
                                "Tapos nang kumain. Mas maayos na ang pakiramdam.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That food helped a lot. Done.",
                            },
                            ["TL"] = {
                                "Nakatulong nang malaki ang pagkain. Tapos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Done eating. Energy restored.",
                            },
                            ["TL"] = {
                                "Tapos nang kumain. Bumalik na ang lakas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Stomach is full. Ready to move.",
                            },
                            ["TL"] = {
                                "Busog na ang tiyan. Handa nang kumilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Finished that meal.",
                            },
                            ["TL"] = {
                                "Natapos na ang pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "All eaten. Good to keep going.",
                            },
                            ["TL"] = {
                                "Naubos na. Maayos na para magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Done. That tasted better than expected.",
                            },
                            ["TL"] = {
                                "Tapos na. Mas masarap kaysa inasahan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Meal completed.",
                            },
                            ["TL"] = {
                                "Kumpleto na ang pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Finished eating. Back on task.",
                            },
                            ["TL"] = {
                                "Tapos nang kumain. Balik sa trabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Rations finished. Strength is back.",
                            },
                            ["TL"] = {
                                "Naubos ang rasyon. Nagbalik ang lakas.",
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
