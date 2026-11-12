-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_completed.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.task_work_completed.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_horde_work.json#records[27]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_task_work_completed_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Task is done. I'm taking a breather.",
                            },
                            ["TL"] = {
                                "Tapos na ang gawain. Magpapahinga muna ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Finished. Inspect it if you want to be sure.",
                            },
                            ["TL"] = {
                                "Tapos na. Suriin mo kung nais mong makatiyak.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "It's completed. Now keep your eyes open.",
                            },
                            ["TL"] = {
                                "Tapos na ito. Ngayon buksan mo ang mga mata mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "That job is handled. Back to guarding the perimeter.",
                            },
                            ["TL"] = {
                                "Naasikaso na ang trabaho. Balik sa pagbabantay ng paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Finished my duty. Nobody snuck up on us, right?",
                            },
                            ["TL"] = {
                                "Tapos na ang tungkulin ko. Walang nakalapit sa atin, di ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Done. Let's make sure it wasn't for nothing.",
                            },
                            ["TL"] = {
                                "Tapos na. Tiyakin nating hindi nasayang ang pagod.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Work is complete. Back on defensive watch.",
                            },
                            ["TL"] = {
                                "Tapos na ang trabaho. Balik sa pagbabantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "It's finished. Keep quiet and stay alert.",
                            },
                            ["TL"] = {
                                "Tapos na. Manatiling tahimik at alisto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Task completed. Don't waste the resources I secured.",
                            },
                            ["TL"] = {
                                "Gawain natapos. Huwag mong sayangin ang naasikaso ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Done. What's the next threat we need to manage?",
                            },
                            ["TL"] = {
                                "Tapos na. Ano ang susunod na banta na dapat harapin?",
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
