-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.drink.completed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.drink.completed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_drink_completed",
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
                ["responseTemplateID"] = "semantic.task.drink.completed",
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
                                "Much better. Thirst is gone.",
                            },
                            ["TL"] = {
                                "Mas maayos na. Wala na ang uhaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Finished drinking. Feeling refreshed.",
                            },
                            ["TL"] = {
                                "Tapos nang uminom. Maginhawa na ang pakiramdam.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That hit the spot. Done drinking.",
                            },
                            ["TL"] = {
                                "Eksakto 'yon. Tapos nang uminom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hydrated and ready to move.",
                            },
                            ["TL"] = {
                                "May sapat nang tubig at handang kumilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Finished that drink.",
                            },
                            ["TL"] = {
                                "Naubos na ang inumin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Done. Throat isn't parched anymore.",
                            },
                            ["TL"] = {
                                "Tapos na. Di na tuyo ang lalamunan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "All drank. Ready for action.",
                            },
                            ["TL"] = {
                                "Nainom na lahat. Handa na sa aksyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Finished having a drink.",
                            },
                            ["TL"] = {
                                "Natapos nang uminom.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Done drinking. Let's keep going.",
                            },
                            ["TL"] = {
                                "Tapos nang uminom. Tuloy na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hydration complete.",
                            },
                            ["TL"] = {
                                "Kumpleto na ang pag-inom.",
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
