-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.give.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.give.failed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[28]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_give_failed",
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
                ["responseTemplateID"] = "semantic.task.give.failed",
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
                                "I couldn't give that to you.",
                            },
                            ["TL"] = {
                                "Hindi ko naibigay iyon sa iyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Handoff failed. You were out of reach.",
                            },
                            ["TL"] = {
                                "Pumalpak ang pag-aabot. Masyado kang malayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Your hands or pack were full. Couldn't give it.",
                            },
                            ["TL"] = {
                                "Puno ang kamay o bag mo. Di maibigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Action interrupted. Item not given.",
                            },
                            ["TL"] = {
                                "Naabala ang kilos. Di naibigay ang gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to transfer the item to you.",
                            },
                            ["TL"] = {
                                "Di mailipat ang gamit sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to hand it over. Something got in the way.",
                            },
                            ["TL"] = {
                                "Bigo sa pag-aabot. May humarang sa pagitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't complete the give action.",
                            },
                            ["TL"] = {
                                "Di ko natapos ang pagbibigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Dropped it during the exchange.",
                            },
                            ["TL"] = {
                                "Nahulog habang nagpapalitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Give task failed.",
                            },
                            ["TL"] = {
                                "Bigo ang gawaing magbigay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Could not give that item.",
                            },
                            ["TL"] = {
                                "Hindi naibigay ang bagay na 'yan.",
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
