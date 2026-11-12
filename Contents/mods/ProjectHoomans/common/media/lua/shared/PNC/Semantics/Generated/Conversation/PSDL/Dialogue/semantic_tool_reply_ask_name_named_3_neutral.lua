-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["id"] = "semantic.tool_reply.ask_name.named.3.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.ask_name.named.3.neutral",
            ["sourcePath"] = "psdl/dialogue/social_tool_replies_affirmation.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_ask_name_named_3_neutral",
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
                ["responseTemplateID"] = "semantic.tool_reply.ask_name.named.3",
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
                                "You can call me %s.",
                            },
                            ["TL"] = {
                                "Maaari mo akong tawaging %s.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Go ahead and call me %s.",
                            },
                            ["TL"] = {
                                "Sige lang, tawagin mo akong %s.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "%s works fine for me.",
                            },
                            ["TL"] = {
                                "Ayos na ang %s para sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm %s. That's the handle I go by.",
                            },
                            ["TL"] = {
                                "Ako si %s. Iyan ang ginagamit kong pagkakakilanlan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "You may call me %s if you'd like.",
                            },
                            ["TL"] = {
                                "Maaari mo akong tawaging %s kung nais mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "%s is what my companions call me.",
                            },
                            ["TL"] = {
                                "%s ang tawag sa akin ng mga kasamahan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I prefer %s, if you're asking.",
                            },
                            ["TL"] = {
                                "Mas gusto ko ang %s, kung nagtatanong ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Call me %s. Simple enough to remember.",
                            },
                            ["TL"] = {
                                "Tawagin mo akong %s. Madaling matandaan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "%s is the name. Keep it in mind.",
                            },
                            ["TL"] = {
                                "%s ang pangalan. Itatak mo sa isip mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm %s. Let's make sure we both survive today.",
                            },
                            ["TL"] = {
                                "Ako si %s. Siguraduhin nating pareho tayong mabuhay ngayon.",
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
