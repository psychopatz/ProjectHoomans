-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_assigned.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.task_work_assigned.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_horde_work.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_task_work_assigned_neutral",
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
                ["responseTemplateID"] = "semantic.interaction.scene.task_work_assigned",
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
                                "I've got work to do. I'll get on it.",
                            },
                            ["TL"] = {
                                "May trabaho akong gagawin. Aasikasuhin ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Starting on the task now.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Sisimulan ko na ang gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Task received. I'll take care of this.",
                            },
                            ["TL"] = {
                                "Natanggap ang utos. Ako na ang bahala rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Getting down to business.",
                            },
                            ["TL"] = {
                                "Sige. Sisimulan na ang trabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'm on it. Shouldn't take too long.",
                            },
                            ["TL"] = {
                                "Inaasikaso ko na. Hindi magtatagal ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I will handle this duty.",
                            },
                            ["TL"] = {
                                "Naintindihan. Hahawakan ko ang tungkuling ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Got my assignment. Moving out to work.",
                            },
                            ["TL"] = {
                                "Nakuha ko ang atas ko. Kikilos na para magtrabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. Time to get my hands dirty.",
                            },
                            ["TL"] = {
                                "Makatwiran. Oras na para magbanat ng buto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll see that this gets done properly.",
                            },
                            ["TL"] = {
                                "Titiyakin kong matatapos ito nang maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Acknowledged. Working on the assigned job.",
                            },
                            ["TL"] = {
                                "Kinikilala ko. Gagawin na ang iniatas na trabaho.",
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
