-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.wait_at.admitted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.wait_at.admitted",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[36]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_wait_at_admitted",
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
                ["responseTemplateID"] = "semantic.task.wait_at.admitted",
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
                                "Okay, I'll wait there.",
                            },
                            ["TL"] = {
                                "Sige, maghihintay ako roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Moving to the waiting spot.",
                            },
                            ["TL"] = {
                                "Naintindihan. Papatungo sa pwesto ng paghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll go stand by over there.",
                            },
                            ["TL"] = {
                                "Pupunta ako roon para maghintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "All right, I'll wait at that position.",
                            },
                            ["TL"] = {
                                "Sige, maghihintay ako sa posisyong iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Heading to the waypoint to wait.",
                            },
                            ["TL"] = {
                                "Papatungo sa marka para maghintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I will hold that ground.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Hahawakan ko ang lupang iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Setting up to wait there.",
                            },
                            ["TL"] = {
                                "Sige. Mag-aayos para maghintay doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll wait at the assigned marker.",
                            },
                            ["TL"] = {
                                "Maghihintay ako sa iniatas na marka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Moving to wait as ordered.",
                            },
                            ["TL"] = {
                                "Kikilos para maghintay ayon sa utos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds good. Going to wait there.",
                            },
                            ["TL"] = {
                                "Maganda 'yan. Pupunta para maghintay doon.",
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
