-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.queued_hostile.1",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.queued_hostile.1",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[27]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_queued_hostile_1",
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
                ["category"] = "projecthoomans:tool_replies",
                ["contentOwner"] = "projecthoomans.dialogue_content.tool_replies",
                ["responseTemplateID"] = "semantic.tool_reply.queued_hostile.1",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/queued_hostile.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I heard you. Watch yourself.",
                            },
                            ["TL"] = {
                                "Narinig kita. Mag-ingat ka sa sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Heard that tone. Mind your step.",
                            },
                            ["TL"] = {
                                "Narinig ko ang tonong 'yan. Mag-ingat sa hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I heard the anger. Keep it in check.",
                            },
                            ["TL"] = {
                                "Narinig ko ang galit. Kontrolin mo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you, but don't cross the line.",
                            },
                            ["TL"] = {
                                "Narinig kita, pero huwag mong tawirin ang hangganan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Message heard. Control yourself.",
                            },
                            ["TL"] = {
                                "Narinig ang mensahe. Magpigil ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Heard that loud and clear. Back off.",
                            },
                            ["TL"] = {
                                "Narinig nang malakas at malinaw. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I heard you. Don't make a mistake you can't undo.",
                            },
                            ["TL"] = {
                                "Narinig kita. Huwag kang gumawa ng pagkakamaling di mo mababawi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I heard the threat. Tread lightly.",
                            },
                            ["TL"] = {
                                "Narinig ko ang banta. Mag-ingat sa pagtapak.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. Don't let your temper get you killed.",
                            },
                            ["TL"] = {
                                "Tala ko na. Huwag mong hayaang mapatay ka ng galit mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you. Watch your back.",
                            },
                            ["TL"] = {
                                "Narinig kita. Bantayan mo ang likod mo.",
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
        ["sourceShard"] = "psdl/dialogue/task_tool_replies.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
