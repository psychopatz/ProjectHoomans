-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.consume.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.consume.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_consume_rejected",
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
                ["responseTemplateID"] = "semantic.task.consume.rejected",
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
                                "I can't use that right now.",
                            },
                            ["TL"] = {
                                "Hindi ko magamit iyon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I don't need to use that at the moment.",
                            },
                            ["TL"] = {
                                "Di ko kailangang gamitin iyan sa sandaling ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That's not suitable for me right now.",
                            },
                            ["TL"] = {
                                "Di angkop sa akin 'yan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to consume that. Not needed.",
                            },
                            ["TL"] = {
                                "Di magagamit 'yan. Di kailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I can't use that under these conditions.",
                            },
                            ["TL"] = {
                                "Di ko magagamit 'yan sa ganitong kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Save it for later. I don't need it now.",
                            },
                            ["TL"] = {
                                "Itabi mo muna. Di ko kailangan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to consume that. Not appropriate.",
                            },
                            ["TL"] = {
                                "Tumatangging gamitin 'yan. Di nararapat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I don't have a use for that right now.",
                            },
                            ["TL"] = {
                                "Wala akong paggagamitan niyan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't use that. Not the right time.",
                            },
                            ["TL"] = {
                                "Di magagamit 'yan. Maling oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Consume order rejected.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang utos na gamitin.",
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
