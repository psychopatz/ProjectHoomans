-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.cooldown.2",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.cooldown.2",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_cooldown_2",
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
                ["responseTemplateID"] = "semantic.tool_reply.cooldown.2",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/task/tool_replies/cooldown.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Save the sweet talk for tomorrow.",
                            },
                            ["TL"] = {
                                "Itabi mo ang matatamis na salita para bukas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hold your charm for another time.",
                            },
                            ["TL"] = {
                                "Itago mo muna ang diskarte mo sa ibang araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Too much sweet talk for one afternoon.",
                            },
                            ["TL"] = {
                                "Masyadong maraming pambobola para sa isang hapon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We've got work to do. Charm me later.",
                            },
                            ["TL"] = {
                                "May trabaho pa tayo. Paamuhin mo ako mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Save the smooth lines. Focus on survival.",
                            },
                            ["TL"] = {
                                "Itabi ang magagandang linya. Magpokus sa kaligtasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "You're pouring on the charm too thick right now.",
                            },
                            ["TL"] = {
                                "Masyadong makapal ang pambobola mo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Let's take a break from the flirting.",
                            },
                            ["TL"] = {
                                "Magpahinga muna tayo sa paglalandian.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Charm cooldown. Let's get back to reality.",
                            },
                            ["TL"] = {
                                "Palamig muna sa pambobola. Balik tayo sa realidad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I've had my fill of sweet words for today.",
                            },
                            ["TL"] = {
                                "Busog na ako sa matatamis na salita para sa araw na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hold that thought until tomorrow morning.",
                            },
                            ["TL"] = {
                                "Hawakan mo ang linyang 'yan hanggang bukas ng umaga.",
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
