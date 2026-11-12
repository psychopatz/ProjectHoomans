-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_greeting",
        ["id"] = "semantic.flow.greeting.opening.default.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.flow.greeting.opening.default.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_greeting.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_flow_greeting_opening_default_neutral",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.flow.greeting.opening.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/greeting.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hey there. Good to see you.",
                            },
                            ["TL"] = {
                                "Uy, mabuti at nakita kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hello there. How are things?",
                            },
                            ["TL"] = {
                                "Kumusta. Kumusta ang lagay?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Good to see you.",
                            },
                            ["TL"] = {
                                "Mabuti at nakita kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Morning. Hope the day treats you well.",
                            },
                            ["TL"] = {
                                "Magandang umaga. Sana maayos ang araw mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hey again. What's going on?",
                            },
                            ["TL"] = {
                                "Uy ulit. Anong nangyayari?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "There you are. Everything quiet?",
                            },
                            ["TL"] = {
                                "Nandiyan ka pala. Tahimik ba ang lahat?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Afternoon. Staying out of trouble?",
                            },
                            ["TL"] = {
                                "Magandang hapon. Ligtas ka ba sa gulo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hello. Good to run into another living person.",
                            },
                            ["TL"] = {
                                "Kumusta. Mabuti at may nakasalubong akong buhay pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Hey. How's the perimeter looking?",
                            },
                            ["TL"] = {
                                "Uy. Kumusta ang paligid?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Evening. Still on your feet, I see.",
                            },
                            ["TL"] = {
                                "Magandang gabi. Nakatayo ka pa rin pala.",
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
        ["sourceShard"] = "psdl/dialogue/conversation_greeting.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
