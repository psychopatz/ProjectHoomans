-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.eat.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.eat.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_eat_rejected",
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
                ["responseTemplateID"] = "semantic.task.eat.rejected",
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
                                "I'm not hungry right now.",
                            },
                            ["TL"] = {
                                "Hindi ako nagugutom ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I don't need food at the moment.",
                            },
                            ["TL"] = {
                                "Di ko kailangan ng pagkain sa sandaling ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already completely full.",
                            },
                            ["TL"] = {
                                "Busog na busog pa ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Save the food. I don't need to eat yet.",
                            },
                            ["TL"] = {
                                "Itabi ang pagkain. Di ko pa kailangang kumain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to eat that. Looks unwholesome.",
                            },
                            ["TL"] = {
                                "Tumatangging kainin 'yan. Mukhang marumi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Can't eat right now. Too tense.",
                            },
                            ["TL"] = {
                                "Di makakain ngayon. Masyadong tensiyonado.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I have enough energy. Keeping rations safe.",
                            },
                            ["TL"] = {
                                "May sapat pa akong lakas. Itatabi ang rasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "No need for a meal yet.",
                            },
                            ["TL"] = {
                                "Wala pang pangangailangan sa pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Eat order rejected. Stomach is satisfied.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang utos na kumain. Busog ang tiyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I can't eat that right now.",
                            },
                            ["TL"] = {
                                "Di ko makakain 'yan ngayon.",
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
