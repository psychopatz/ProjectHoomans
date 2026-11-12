-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["id"] = "semantic.tool_reply.compliment.3.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.compliment.3.neutral",
            ["sourcePath"] = "psdl/dialogue/social_tool_replies_affirmation.json#records[21]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_compliment_3_neutral",
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
                ["responseTemplateID"] = "semantic.tool_reply.compliment.3",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/tool_replies/compliment.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "You noticed. Thank you.",
                            },
                            ["TL"] = {
                                "Napansin mo pala. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Glad somebody noticed.",
                            },
                            ["TL"] = {
                                "Mabuti naman at may nakapansin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I was wondering if anyone would catch that. Thanks.",
                            },
                            ["TL"] = {
                                "Iniisip ko nga kung may makakapansin niyan. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Good eye. Thanks for noticing.",
                            },
                            ["TL"] = {
                                "Matalas ang paningin mo. Salamat sa pagpansin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I put some effort into that. Good to see it showed.",
                            },
                            ["TL"] = {
                                "Pinaghirapan ko 'yon. Mabuti at lumitaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. Nice to know it did not go unseen.",
                            },
                            ["TL"] = {
                                "Salamat. Masarap malaman na hindi 'yon nabalewala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "You have sharp observation skills. Thank you.",
                            },
                            ["TL"] = {
                                "Alesto ka magmasid. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate you noticing that detail.",
                            },
                            ["TL"] = {
                                "Salamat at napansin mo ang detalyeng 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I try my best. Thank you for noticing.",
                            },
                            ["TL"] = {
                                "Ginagawa ko ang buong makakaya ko. Salamat sa pagpansin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. That was worth the effort then.",
                            },
                            ["TL"] = {
                                "Salamat. Naging sulit ang pagod ko dahil diyan.",
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
