-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_completed.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.task_work_completed.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_horde_work.json#records[24]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_task_work_completed_neutral",
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
                ["category"] = "projecthoomans:core_social_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.social",
                ["responseTemplateID"] = "semantic.interaction.scene.task_work_completed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/work.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's done. One less thing to worry about.",
                            },
                            ["TL"] = {
                                "Tapos na. Isang alalahanin ang nabawas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Finished the task. All wrapped up.",
                            },
                            ["TL"] = {
                                "Tapos na ang gawain. Ayos na ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Job is complete. What's next?",
                            },
                            ["TL"] = {
                                "Tapos na ang trabaho. Ano ang susunod?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "That takes care of that assignment.",
                            },
                            ["TL"] = {
                                "Naasikaso na ang tungkuling iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "All done here. Everything looks in order.",
                            },
                            ["TL"] = {
                                "Tapos na ang lahat dito. Maayos ang kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Task is completed to the best of my ability.",
                            },
                            ["TL"] = {
                                "Natapos ang gawain sa abot ng aking makakaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Wrapped that up. Ready for the next priority.",
                            },
                            ["TL"] = {
                                "Tapos na iyon. Handa na para sa susunod na prayoridad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Done. That should hold up fine.",
                            },
                            ["TL"] = {
                                "Tapos na. Maayos ang magiging tibay niyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "The work is finished. Moving on.",
                            },
                            ["TL"] = {
                                "Tapos na ang trabaho. Magpatuloy na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Completed. Duty handled.",
                            },
                            ["TL"] = {
                                "Kumpleto na. Naasikaso ang tungkulin.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_horde_work.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
