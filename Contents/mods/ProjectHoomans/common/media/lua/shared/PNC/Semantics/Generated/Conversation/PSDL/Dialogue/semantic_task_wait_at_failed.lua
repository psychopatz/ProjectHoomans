-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.wait_at.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.wait_at.failed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[38]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_wait_at_failed",
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
                ["responseTemplateID"] = "semantic.task.wait_at.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/lifecycle/wait_at.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't wait there.",
                            },
                            ["TL"] = {
                                "Hindi ako nakapaghintay roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Position was overrun. Couldn't keep waiting.",
                            },
                            ["TL"] = {
                                "Pinamugaran ang pwesto. Di nakapagpatuloy maghintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Enemies forced me out of the waiting spot.",
                            },
                            ["TL"] = {
                                "Itinaboy ako ng kalaban mula sa pwesto ng paghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't reach the designated waiting location.",
                            },
                            ["TL"] = {
                                "Di narating ang itinalagang lugar ng paghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to hold ground there. Too dangerous.",
                            },
                            ["TL"] = {
                                "Di mahawakan ang lupa roon. Masyadong mapanganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Waiting failed. Had to relocate for safety.",
                            },
                            ["TL"] = {
                                "Pumalpak ang paghihintay. Kinailangang lumipat para sa kaligtasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Aborted waiting. Sector became hostile.",
                            },
                            ["TL"] = {
                                "Itinigil ang paghihintay. Naging delikado ang lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I had to abandon the post.",
                            },
                            ["TL"] = {
                                "Kinailangan kong iwan ang poste.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Could not remain stationary there.",
                            },
                            ["TL"] = {
                                "Hindi nakapanatiling nakatigil doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to hold the wait point.",
                            },
                            ["TL"] = {
                                "Bigo sa paghawak ng pwesto ng paghihintay.",
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
