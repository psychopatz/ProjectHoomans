-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.eat.active",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.eat.active",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_eat_active",
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
                ["responseTemplateID"] = "semantic.task.eat.active",
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
                                "Eating now.",
                            },
                            ["TL"] = {
                                "Kumakain na ako ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Having a bite right now.",
                            },
                            ["TL"] = {
                                "Kumakain ng kaunti ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Chewing through some food. Give me a moment.",
                            },
                            ["TL"] = {
                                "Kumakain ng pagkain. Sandali lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Currently eating.",
                            },
                            ["TL"] = {
                                "Kasalukuyang kumakain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Getting some calories in me.",
                            },
                            ["TL"] = {
                                "Nagpapasok ng lakas sa katawan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Eating my rations now.",
                            },
                            ["TL"] = {
                                "Kinakain ang baong pagkain ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Taking a meal break as instructed.",
                            },
                            ["TL"] = {
                                "Kumakain ayon sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Eating. Needed the energy.",
                            },
                            ["TL"] = {
                                "Kumakain. Kailangan ko ng lakas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Having some food now.",
                            },
                            ["TL"] = {
                                "Kumakain na ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Eating quietly. Won't be long.",
                            },
                            ["TL"] = {
                                "Kumakain nang tahimik. Saglit lang ito.",
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
