-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["id"] = "semantic.tool_reply.ask_name.rejected.1.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.ask_name.rejected.1.neutral",
            ["sourcePath"] = "psdl/dialogue/social_tool_replies_affirmation.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_ask_name_rejected_1_neutral",
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
                ["responseTemplateID"] = "semantic.tool_reply.ask_name.rejected.1",
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
                                "I am not ready to share that yet.",
                            },
                            ["TL"] = {
                                "Hindi pa ako handang sabihin iyan sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We don't know each other well enough for names.",
                            },
                            ["TL"] = {
                                "Hindi pa tayo lubos na magkakilala para sa mga pangalan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Names are a luxury for trusted folks. Keep your distance.",
                            },
                            ["TL"] = {
                                "Para lang sa pinagkakatiwalaan ang pangalan. Lumayo ka muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I prefer to remain anonymous for now.",
                            },
                            ["TL"] = {
                                "Mas gusto kong manatiling walang pangalan sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Not sharing my name with someone I just met.",
                            },
                            ["TL"] = {
                                "Hindi ko ibinabahagi ang pangalan ko sa kakatagpo ko lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "You don't need my name to deal with me.",
                            },
                            ["TL"] = {
                                "Hindi mo kailangan ang pangalan ko para makipag-usap sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I keep my identity to myself out here. Back off.",
                            },
                            ["TL"] = {
                                "Itinatago ko ang pagkakakilanlan ko dito. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "That information stays private between me and my people.",
                            },
                            ["TL"] = {
                                "Pribado ang impormasyong 'yan sa akin at sa mga kasama ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not in the habit of giving names to armed strangers.",
                            },
                            ["TL"] = {
                                "Hindi ako sanay magbigay ng pangalan sa mga armadong di-kilala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "No names today. Let's keep things strictly professional.",
                            },
                            ["TL"] = {
                                "Walang pangalan ngayon. Panatilihin nating pormal ang lahat.",
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
