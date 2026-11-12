-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "task_tool_replies",
        ["id"] = "semantic.tool_reply.cooldown.1",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.cooldown.1",
            ["sourcePath"] = "psdl/dialogue/task_tool_replies.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_cooldown_1",
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
                ["responseTemplateID"] = "semantic.tool_reply.cooldown.1",
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
                                "You have had your turn with the compliments today.",
                            },
                            ["TL"] = {
                                "Nakaubos ka na ng papuri para sa araw na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Save some of those kind words for tomorrow.",
                            },
                            ["TL"] = {
                                "Itabi mo ang ilan sa magagandang salita para bukas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You already flattered me enough for one day.",
                            },
                            ["TL"] = {
                                "Sobra-sobra na ang pambobola mo para sa isang araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Praise limit reached. Let's get back to surviving.",
                            },
                            ["TL"] = {
                                "Sapat na ang papuri. Balik na tayo sa pagligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I heard you the first few times. Let it rest.",
                            },
                            ["TL"] = {
                                "Narinig na kita kanina pa. Ipahinga mo muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "We've traded enough compliments for today.",
                            },
                            ["TL"] = {
                                "Sapat na ang palitan natin ng papuri ngayong araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Easy on the flattery. Don't overdo it.",
                            },
                            ["TL"] = {
                                "Dahan-dahan sa pambobola. Huwag mong sobrahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Give it a rest until tomorrow.",
                            },
                            ["TL"] = {
                                "Ipahinga mo muna hanggang bukas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "One compliment per day is plenty out here.",
                            },
                            ["TL"] = {
                                "Ang isang papuri kada araw ay marami na rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Save your breath. You've hit the limit for now.",
                            },
                            ["TL"] = {
                                "Itabi mo ang laway mo. Naabot mo na ang hangganan sa ngayon.",
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
