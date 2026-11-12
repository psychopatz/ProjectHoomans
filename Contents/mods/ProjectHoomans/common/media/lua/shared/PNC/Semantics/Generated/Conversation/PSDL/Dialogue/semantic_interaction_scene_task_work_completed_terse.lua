-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_completed.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.task_work_completed.terse",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_horde_work.json#records[26]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_task_work_completed_terse",
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
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Done.",
                            },
                            ["TL"] = {
                                "Tapos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Finished.",
                            },
                            ["TL"] = {
                                "Tapos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Completed.",
                            },
                            ["TL"] = {
                                "Kumpleto.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Handled.",
                            },
                            ["TL"] = {
                                "Naasikaso na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Sorted.",
                            },
                            ["TL"] = {
                                "Ayos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "All set.",
                            },
                            ["TL"] = {
                                "Handa na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Wrapped up.",
                            },
                            ["TL"] = {
                                "Tapos na lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Next?",
                            },
                            ["TL"] = {
                                "Susunod?",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Cleared.",
                            },
                            ["TL"] = {
                                "Malinaw na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Ready.",
                            },
                            ["TL"] = {
                                "Handa na.",
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
