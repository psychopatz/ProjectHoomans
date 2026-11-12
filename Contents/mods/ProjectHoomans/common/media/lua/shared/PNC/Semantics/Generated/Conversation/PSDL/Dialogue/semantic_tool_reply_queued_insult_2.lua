-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.queued_insult.2",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.queued_insult.2",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[30]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_queued_insult_2",
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
                ["responseTemplateID"] = "semantic.tool_reply.queued_insult.2",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/queued_insult.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Noted.",
                            },
                            ["TL"] = {
                                "Tala ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Noted, and dismissed.",
                            },
                            ["TL"] = {
                                "Tala ko na, at binalewala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. You're wasting your breath.",
                            },
                            ["TL"] = {
                                "Tala ko na. Sinasayang mo lang ang laway mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. Doesn't mean a thing to me.",
                            },
                            ["TL"] = {
                                "Tala ko na. Walang halaga sa akin 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Duly noted. Try harder next time.",
                            },
                            ["TL"] = {
                                "Tala ko na. Galingan mo sa susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. I've heard worse from strangers.",
                            },
                            ["TL"] = {
                                "Tala ko na. Nakarining na ako ng mas masahol pa sa iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. Water off a duck's back.",
                            },
                            ["TL"] = {
                                "Tala ko na. Para lang tubig sa dahon ng gabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. Don't expect a reaction.",
                            },
                            ["TL"] = {
                                "Tala ko na. Huwag kang umasa ng reaksyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. Moving along.",
                            },
                            ["TL"] = {
                                "Tala ko na. Tuloy ang lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Noted and ignored.",
                            },
                            ["TL"] = {
                                "Tala ko na at kinalimutan.",
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
