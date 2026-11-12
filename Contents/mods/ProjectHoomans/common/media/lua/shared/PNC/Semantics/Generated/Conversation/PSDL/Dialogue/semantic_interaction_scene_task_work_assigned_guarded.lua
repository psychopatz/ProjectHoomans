-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_horde_work",
        ["id"] = "semantic.interaction.scene.task_work_assigned.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.task_work_assigned.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_horde_work.json#records[23]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_task_work_assigned_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll do the work. Watch my back while I do.",
                            },
                            ["TL"] = {
                                "Gagawin ko ang trabaho. Bantayan mo ang likod ko habang ginagawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'll handle it, but keep an eye on our surroundings.",
                            },
                            ["TL"] = {
                                "Ako na ang bahala, pero magmasid ka sa paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Don't crowd me while I'm working.",
                            },
                            ["TL"] = {
                                "Naintindihan. Huwag mo akong dikitan habang nagtatrabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll do my share. Make sure you do yours.",
                            },
                            ["TL"] = {
                                "Gagawin ko ang bahagi ko. Tiyakin mong gagawin mo ang sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Getting on it. Stay alert for threats.",
                            },
                            ["TL"] = {
                                "Sisimulan na. Manatiling alisto sa mga banta.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll get it done. Just make sure the perimeter is secure.",
                            },
                            ["TL"] = {
                                "Matatapos ko ito. Tiyakin mo lang na ligtas ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Task noted. I'll finish it without distraction.",
                            },
                            ["TL"] = {
                                "Tala ang gawain. Tatapusin ko nang walang abala.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. I'll see to the task.",
                            },
                            ["TL"] = {
                                "Sige. Aasikasuhin ko ang gawain.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll handle this. Keep your weapon ready.",
                            },
                            ["TL"] = {
                                "Hahawakan ko ito. Ihanda mo ang armas mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Don't let anything sneak up on me.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Huwag kang magpapapasok ng kahit ano sa likod ko.",
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
