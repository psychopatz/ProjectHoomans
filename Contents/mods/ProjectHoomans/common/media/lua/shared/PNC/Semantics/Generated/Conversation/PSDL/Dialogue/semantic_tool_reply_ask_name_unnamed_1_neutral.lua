-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["id"] = "semantic.tool_reply.ask_name.unnamed.1.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.ask_name.unnamed.1.neutral",
            ["sourcePath"] = "psdl/dialogue/social_tool_replies_affirmation.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_ask_name_unnamed_1_neutral",
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
                ["responseTemplateID"] = "semantic.tool_reply.ask_name.unnamed.1",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/tool_replies/ask_name.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "You want to know my name? Give me a second.",
                            },
                            ["TL"] = {
                                "Gusto mong malaman ang pangalan ko? Bigyan mo ako ng sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't heard anyone call me by name in months.",
                            },
                            ["TL"] = {
                                "Ilang buwan na mula noong may tumawag sa pangalan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "A name? Almost forgot people still used them.",
                            },
                            ["TL"] = {
                                "Pangalan? Halos nakalimutan ko nang may gumagamit pa niyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Takes a moment to remember what folks used to call me.",
                            },
                            ["TL"] = {
                                "Inaalala ko pa kung ano ang tawag sa akin ng mga tao noon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Funny question. Been so long since I introduced myself.",
                            },
                            ["TL"] = {
                                "Nakakatuwang tanong. Matagal na mula noong huling nagpakilala ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hold on, let me think back to what I was called before this.",
                            },
                            ["TL"] = {
                                "Teka lang, inaalala ko kung ano ang tawag sa akin bago ang lahat ng ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "My name... feels like another person owned it.",
                            },
                            ["TL"] = {
                                "Ang pangalan ko... parang ibang tao ang nagmamay-ari noon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just a survivor out here. But give me a second to recall.",
                            },
                            ["TL"] = {
                                "Isa lang akong nakaligtas dito. Pero bigyan mo ako ng sandali para alalahanin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Doesn't come to mind as fast as it used to.",
                            },
                            ["TL"] = {
                                "Hindi na agad pumapasok sa isip ko gaya ng dati.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "A name... give me a moment to dust off the cobwebs.",
                            },
                            ["TL"] = {
                                "Pangalan... bigyan mo ako ng sandali para alalahanin.",
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
        ["sourceShard"] = "psdl/dialogue/social_tool_replies_affirmation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
