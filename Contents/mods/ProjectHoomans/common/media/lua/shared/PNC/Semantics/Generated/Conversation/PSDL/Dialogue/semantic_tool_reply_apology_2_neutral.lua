-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_tool_replies_affirmation",
        ["id"] = "semantic.tool_reply.apology.2.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.tool_reply.apology.2.neutral",
            ["sourcePath"] = "psdl/dialogue/social_tool_replies_affirmation.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_tool_reply_apology_2_neutral",
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
                ["responseTemplateID"] = "semantic.tool_reply.apology.2",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/tool_replies/apology.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I accept the apology.",
                            },
                            ["TL"] = {
                                "Tinatanggap ko ang tawad mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Apology accepted. We are fine.",
                            },
                            ["TL"] = {
                                "Tanggap ko na. Ayos na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I appreciate you owning up to it.",
                            },
                            ["TL"] = {
                                "Salamat at inamin mo ang pagkakamali mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Takes guts to say that out here. I accept.",
                            },
                            ["TL"] = {
                                "Kailangan ng tapang para aminin 'yan dito. Tanggap ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you. Apology accepted.",
                            },
                            ["TL"] = {
                                "Salamat. Tanggap ko ang paumanhin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "We all make mistakes under pressure. Accepted.",
                            },
                            ["TL"] = {
                                "Lahat naman nagkakamali kapag tensiyonado. Tanggap ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you, and I accept.",
                            },
                            ["TL"] = {
                                "Narinig kita, at tanggap ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. Apology accepted.",
                            },
                            ["TL"] = {
                                "Makatwiran. Tanggap ko ang paumanhin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Good. I accept your apology.",
                            },
                            ["TL"] = {
                                "Mabuti. Tinatanggap ko ang tawad mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I appreciate the honesty. We are good.",
                            },
                            ["TL"] = {
                                "Salamat sa katapatan. Ayos na tayo.",
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
