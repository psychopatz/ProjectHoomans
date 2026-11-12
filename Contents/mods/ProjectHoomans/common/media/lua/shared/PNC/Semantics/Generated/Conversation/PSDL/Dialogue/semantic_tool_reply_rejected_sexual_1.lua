-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.rejected_sexual.1",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.rejected_sexual.1",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[43]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_rejected_sexual_1",
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
                ["responseTemplateID"] = "semantic.tool_reply.rejected_sexual.1",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/rejected_sexual.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That is not happening.",
                            },
                            ["TL"] = {
                                "Hindi iyan mangyayari.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Not a chance. Forget about it.",
                            },
                            ["TL"] = {
                                "Walang pag-asa. Kalimutan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I am not interested in that at all.",
                            },
                            ["TL"] = {
                                "Hindi talaga ako interesado riyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "That is completely off the table.",
                            },
                            ["TL"] = {
                                "Wala sa pagpipilian 'yan kailanman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "No. Never going to happen.",
                            },
                            ["TL"] = {
                                "Hindi. Di kailanman mangyayari.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Absolutely not.",
                            },
                            ["TL"] = {
                                "Hinding-hindi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm shutting that down right now. No.",
                            },
                            ["TL"] = {
                                "Papatayin ko ang paksang 'yan ngayon. Hindi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "That won't be happening between us.",
                            },
                            ["TL"] = {
                                "Hindi 'yan mangyayari sa pagitan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Drop that idea entirely. Not happening.",
                            },
                            ["TL"] = {
                                "Iwan mo nang buo ang ideyang 'yan. Di mangyayari.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "No means no. It's not happening.",
                            },
                            ["TL"] = {
                                "Ang hindi ay hindi. Di mangyayari 'yan.",
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
