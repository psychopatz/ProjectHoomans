-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_stressed.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_stressed.terse",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_stressed_terse",
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
                ["responseTemplateID"] = "semantic.social.dispute_stressed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "Not now.",
                            },
                            ["TL"] = {
                                "Hindi ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "Stop.",
                            },
                            ["TL"] = {
                                "Tigil.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "Cool it.",
                            },
                            ["TL"] = {
                                "Kumalma ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "Later.",
                            },
                            ["TL"] = {
                                "Mamaya na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "Drop it.",
                            },
                            ["TL"] = {
                                "Hayaan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "Too tense.",
                            },
                            ["TL"] = {
                                "Masyadong delikado.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hold your tongue.",
                            },
                            ["TL"] = {
                                "Pigilin ang dila.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "Focus.",
                            },
                            ["TL"] = {
                                "Magpokus.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "Enough.",
                            },
                            ["TL"] = {
                                "Sapat na.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "Quiet.",
                            },
                            ["TL"] = {
                                "Tahimik.",
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
        ["sourceShard"] = "psdl/dialogue/social_reactions_ack_dispute.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
