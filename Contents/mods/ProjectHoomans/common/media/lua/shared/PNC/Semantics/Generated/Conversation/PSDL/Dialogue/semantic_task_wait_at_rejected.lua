-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_lifecycle",
        ["id"] = "semantic.task.wait_at.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.task.wait_at.rejected",
            ["sourcePath"] = "psdl/dialogue/task_lifecycle.json#records[39]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_task_wait_at_rejected",
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
                ["responseTemplateID"] = "semantic.task.wait_at.rejected",
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
                                "I can't wait there right now.",
                            },
                            ["TL"] = {
                                "Hindi ako makapaghintay roon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That spot is in the line of fire. I won't wait there.",
                            },
                            ["TL"] = {
                                "Nasa linya ng putukan ang pwestong 'yon. Di ako maghihintay doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Standing out in the open like that is suicide.",
                            },
                            ["TL"] = {
                                "Pagpapakamatay ang tumayo sa bukas na lugar nang ganoon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to wait in an unsecured position.",
                            },
                            ["TL"] = {
                                "Tumatangging maghintay sa di-ligtas na posisyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Too many hostiles nearby to just stand around.",
                            },
                            ["TL"] = {
                                "Masyadong maraming kalaban sa paligid para tumayo-tayo lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I need to stay on the move. Can't wait there.",
                            },
                            ["TL"] = {
                                "Kailangan kong gumalaw. Di makapaghihintay doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Wait order rejected. Find a safer spot.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang paghihintay. Maghanap ng mas ligtas na lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I won't wait in a compromised sector.",
                            },
                            ["TL"] = {
                                "Di ako maghihintay sa delikadong lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to comply. That location has zero cover.",
                            },
                            ["TL"] = {
                                "Di makasusunod. Walang silong ang lugar na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I can't wait at that position.",
                            },
                            ["TL"] = {
                                "Di ako makapaghihintay sa posisyong 'yon.",
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
