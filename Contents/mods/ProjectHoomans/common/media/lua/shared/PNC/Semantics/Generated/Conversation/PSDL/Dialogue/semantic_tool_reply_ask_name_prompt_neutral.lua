-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["id"] = "semantic.tool_reply.ask_name.prompt.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.ask_name.prompt.neutral",
            ["sourcePath"] = "psdl/dialogue/social_tool_replies_affirmation.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_ask_name_prompt_neutral",
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
                ["responseTemplateID"] = "semantic.tool_reply.ask_name.prompt",
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
                                "I'll tell you my name once we've established some trust. What's your name?",
                            },
                            ["TL"] = {
                                "Sasabihin ko ang pangalan ko kapag may tiwala na tayo. Ano ang pangalan mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Fair is fair. Tell me who you are first.",
                            },
                            ["TL"] = {
                                "Patas lang dapat. Sabihin mo muna kung sino ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I don't hand my name to strangers. What do they call you?",
                            },
                            ["TL"] = {
                                "Hindi ko ibinibigay ang pangalan ko sa di-kilala. Anong tawag sa 'yo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "How about introductions on your side first? What's your name?",
                            },
                            ["TL"] = {
                                "Paano kung ikaw muna ang magpakilala? Ano ang pangalan mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "You first. Who am I speaking with?",
                            },
                            ["TL"] = {
                                "Ikaw muna. Sino ba ang kausap ko?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Names carry weight out here. Tell me yours before asking mine.",
                            },
                            ["TL"] = {
                                "Mahalaga ang pangalan dito. Sabihin mo muna ang sa 'yo bago magtanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Let's trade names fairly. What should I call you?",
                            },
                            ["TL"] = {
                                "Magpalitan tayo ng pangalan nang patas. Ano dapat ang itawag ko sa 'yo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'd like to know who's asking before I give up my name.",
                            },
                            ["TL"] = {
                                "Gusto ko munang malaman kung sino ang nagtatanong bago ko ibigay ang akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Give me your name first, then maybe I'll share mine.",
                            },
                            ["TL"] = {
                                "Ibigay mo muna ang pangalan mo, baka sakaling ibahagi ko rin ang akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Introduce yourself first. It's only polite in these times.",
                            },
                            ["TL"] = {
                                "Magpakilala ka muna. Pagpapakita 'yon ng galang sa panahong ito.",
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
