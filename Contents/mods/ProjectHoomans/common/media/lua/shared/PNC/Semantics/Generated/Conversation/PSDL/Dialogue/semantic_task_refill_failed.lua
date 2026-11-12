-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.refill.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.refill.failed",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[33]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_refill_failed",
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
                ["responseTemplateID"] = "semantic.task.refill.failed",
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
                                "I couldn't refill that.",
                            },
                            ["TL"] = {
                                "Hindi ko nalagyan ng laman iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The water source was dry or cut off.",
                            },
                            ["TL"] = {
                                "Tuyot o putol ang pinagkukunan ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to refill. Water was contaminated.",
                            },
                            ["TL"] = {
                                "Bigo sa pagpuno. Kontaminado ang tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I was interrupted while trying to gather water.",
                            },
                            ["TL"] = {
                                "Naabala ako habang sumusubok kumuha ng tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to find a functional water tap.",
                            },
                            ["TL"] = {
                                "Walang makitang gumaganang gripo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Container is damaged or cracked. Refill failed.",
                            },
                            ["TL"] = {
                                "May basag ang lalagyan. Pumalpak ang pagpuno.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't reach the source safely.",
                            },
                            ["TL"] = {
                                "Di maabot ang pinagkukunan nang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hostiles near the water source. Refill aborted.",
                            },
                            ["TL"] = {
                                "May kalaban malapit sa tubig. Itinigil ang pagpuno.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Action failed. Bottle still empty.",
                            },
                            ["TL"] = {
                                "Bigo ang kilos. Walang laman pa rin ang bote.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Could not refill container.",
                            },
                            ["TL"] = {
                                "Hindi napuno ang lalagyan.",
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
