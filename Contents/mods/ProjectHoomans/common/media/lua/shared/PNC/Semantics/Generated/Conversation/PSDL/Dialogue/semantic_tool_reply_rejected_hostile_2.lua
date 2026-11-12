-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.rejected_hostile.2",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.rejected_hostile.2",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[42]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_rejected_hostile_2",
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
                ["responseTemplateID"] = "semantic.tool_reply.rejected_hostile.2",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/rejected_hostile.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "You do not get to speak to me that way.",
                            },
                            ["TL"] = {
                                "Wala kang karapatang kausapin ako nang ganyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Mind your mouth before someone breaks it for you.",
                            },
                            ["TL"] = {
                                "Bantayan ang bibig mo bago may bumasag niyan para sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You don't talk to me with that disrespect.",
                            },
                            ["TL"] = {
                                "Huwag mo akong kausapin nang may pambabastos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Check your tone right now.",
                            },
                            ["TL"] = {
                                "Ayusin mo ang tono mo ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I won't tolerate that disrespect from anyone.",
                            },
                            ["TL"] = {
                                "Di ko palalampasin ang pambabastos na 'yan kahit kanino.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Who do you think you're talking to?",
                            },
                            ["TL"] = {
                                "Sino sa tingin mo ang kinakausap mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "You have crossed a serious line with that mouth.",
                            },
                            ["TL"] = {
                                "Tumawid ka sa seryosong linya sa bibig mong 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Watch how you address me.",
                            },
                            ["TL"] = {
                                "Bantayan mo kung paano mo ako kausapin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Lower your tone and show some basic respect.",
                            },
                            ["TL"] = {
                                "Hinaan ang tono at magpakita ng simpleng galang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "You don't get to address me like that.",
                            },
                            ["TL"] = {
                                "Hindi mo ako pwedeng kausapin nang ganyan.",
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
