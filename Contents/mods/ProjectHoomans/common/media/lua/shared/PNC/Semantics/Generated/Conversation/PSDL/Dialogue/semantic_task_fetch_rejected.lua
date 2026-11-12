-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.fetch.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.fetch.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_fetch_rejected",
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
                ["responseTemplateID"] = "semantic.task.fetch.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/fetch.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't fetch that right now.",
                            },
                            ["TL"] = {
                                "Hindi ko makuha iyon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's in a death trap. I'm not fetching it.",
                            },
                            ["TL"] = {
                                "Nasa bitag ng kamatayan 'yan. Di ko kukunin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Too far or too dangerous. Refusing to fetch.",
                            },
                            ["TL"] = {
                                "Masyadong malayo o mapanganib. Tumatangging kunin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "My hands and pack are completely full.",
                            },
                            ["TL"] = {
                                "Puno na ang kamay at bag ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I won't risk my neck for that junk.",
                            },
                            ["TL"] = {
                                "Di ko isusugal ang buhay ko para sa basurang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Can't retrieve that under current conditions.",
                            },
                            ["TL"] = {
                                "Di makukuha 'yan sa kasalukuyang kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I don't have the carrying capacity right now.",
                            },
                            ["TL"] = {
                                "Wala na akong espasyong paglalagyan ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Fetch order rejected. Pick it up yourself.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang pagkuha. Pulutin mo nang kusa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to comply. Item is out of bounds.",
                            },
                            ["TL"] = {
                                "Di makasusunod. Di abot ang bagay na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I can't fetch that for you.",
                            },
                            ["TL"] = {
                                "Di ko makukuha 'yan para sa 'yo.",
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
