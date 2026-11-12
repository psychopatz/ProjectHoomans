-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["id"] = "semantic.tool_reply.ask_name.named.2.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.ask_name.named.2.neutral",
            ["sourcePath"] = "psdl/dialogue/social_tool_replies_affirmation.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_ask_name_named_2_neutral",
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
                ["responseTemplateID"] = "semantic.tool_reply.ask_name.named.2",
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
                                "The name is %s.",
                            },
                            ["TL"] = {
                                "%s ang pangalan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'm %s. Nice to meet you properly.",
                            },
                            ["TL"] = {
                                "Ako si %s. Mabuti at pormal tayong nagkakilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You're speaking with %s.",
                            },
                            ["TL"] = {
                                "Kausap mo si %s.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "%s is my name. Don't wear it out.",
                            },
                            ["TL"] = {
                                "%s ang pangalan ko. Tandaan mo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I answer to %s.",
                            },
                            ["TL"] = {
                                "Sumasagot ako sa pangalang %s.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "They call me %s around these parts.",
                            },
                            ["TL"] = {
                                "Tinatawag nila akong %s dito sa lugar na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Name's %s. Glad we got that sorted.",
                            },
                            ["TL"] = {
                                "%s ang pangalan. Mabuti at nalaman mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Just call me %s.",
                            },
                            ["TL"] = {
                                "Tawagin mo na lang akong %s.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm known as %s to the survivors here.",
                            },
                            ["TL"] = {
                                "Kilala ako bilang %s ng mga nakaligtas dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "It's %s. Good to put a name to the face.",
                            },
                            ["TL"] = {
                                "%s ako. Mabuti at may pangalan na ang mukhang ito.",
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
