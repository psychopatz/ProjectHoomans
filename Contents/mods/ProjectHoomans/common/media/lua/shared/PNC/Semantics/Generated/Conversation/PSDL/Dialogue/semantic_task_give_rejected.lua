-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.give.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.give.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[29]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_give_rejected",
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
                ["responseTemplateID"] = "semantic.task.give.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/give.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't give that to you right now.",
                            },
                            ["TL"] = {
                                "Hindi ko maibibigay iyon sa iyo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I need that item to survive. Can't spare it.",
                            },
                            ["TL"] = {
                                "Kailangan ko 'yan para mabuhay. Di ko maipamimigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That is vital to my loadout. I won't give it away.",
                            },
                            ["TL"] = {
                                "Mahalaga 'yan sa gamit ko. Di ko ipamimigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to hand that over.",
                            },
                            ["TL"] = {
                                "Tumatangging iabot 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I don't have that item to give.",
                            },
                            ["TL"] = {
                                "Wala sa akin ang gamit na 'yan para ibigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Can't give that up under these circumstances.",
                            },
                            ["TL"] = {
                                "Di ko maibibigay 'yan sa ganitong kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That's not something I can part with.",
                            },
                            ["TL"] = {
                                "Hindi bagay 'yan na kaya kong bitiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Give order rejected. I'm keeping this.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang pagbibigay. Itatabi ko ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I won't give that item away.",
                            },
                            ["TL"] = {
                                "Di ko ipamimigay ang bagay na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not giving that. Ask for something else.",
                            },
                            ["TL"] = {
                                "Di ibibigay 'yan. Humingi ka ng iba.",
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
