-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.refill.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.refill.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[34]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_refill_rejected",
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
                ["responseTemplateID"] = "semantic.task.refill.rejected",
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
                                "I can't refill that right now.",
                            },
                            ["TL"] = {
                                "Hindi ko malalagyan ng laman iyon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "There is no known clean water source nearby.",
                            },
                            ["TL"] = {
                                "Walang kilalang malinis na tubig sa malapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "The container is already completely full.",
                            },
                            ["TL"] = {
                                "Puno na ang lalagyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Too exposed to stand around pumping water.",
                            },
                            ["TL"] = {
                                "Masyadong lantad para magbomba ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I won't approach that water source. It's a death trap.",
                            },
                            ["TL"] = {
                                "Di ako lalapit sa tubig na 'yan. Bitag 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Can't refill. No suitable vessel available.",
                            },
                            ["TL"] = {
                                "Di makapagpuno. Walang angkop na sisidlan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Refill order rejected. Bad timing.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang pagpuno. Maling oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Water is tainted there. I refuse to collect it.",
                            },
                            ["TL"] = {
                                "Marumi ang tubig doon. Tumatanggi akong kumuha.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We need to deal with threats before refilling.",
                            },
                            ["TL"] = {
                                "Harapin muna natin ang banta bago magpuno.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I can't refill that under current danger.",
                            },
                            ["TL"] = {
                                "Di ko malalagyan 'yan sa gitna ng panganib.",
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
