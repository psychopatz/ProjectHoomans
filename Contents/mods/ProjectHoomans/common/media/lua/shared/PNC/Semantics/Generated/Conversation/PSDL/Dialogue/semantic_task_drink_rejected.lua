-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.drink.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.drink.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_drink_rejected",
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
                ["responseTemplateID"] = "semantic.task.drink.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/drink.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not thirsty right now.",
                            },
                            ["TL"] = {
                                "Hindi ako nauuhaw ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I don't need to drink at the moment.",
                            },
                            ["TL"] = {
                                "Di ko kailangang uminom sa sandaling ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm fully hydrated. Saving the water.",
                            },
                            ["TL"] = {
                                "Busog pa ako sa tubig. Itatabi ang inumin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Can't drink right now. Too dangerous to pause.",
                            },
                            ["TL"] = {
                                "Di pwedeng uminom ngayon. Masyadong mapanganib huminto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to drink that water. It looks tainted.",
                            },
                            ["TL"] = {
                                "Tumatangging inumin ang tubig na 'yan. Mukhang kontaminado.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I have plenty of fluids. Don't need to drink.",
                            },
                            ["TL"] = {
                                "Marami pa akong tubig sa katawan. Di kailangang uminom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "No need for a drink yet.",
                            },
                            ["TL"] = {
                                "Wala pang pangangailangan sa inumin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll save our clean water for later.",
                            },
                            ["TL"] = {
                                "Itatabi ko ang malinis na tubig mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Drink order rejected. Not parched.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang pag-inom. Di ako uhaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Can't drink that right now.",
                            },
                            ["TL"] = {
                                "Di ko maiinom 'yan ngayon.",
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
