-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.offer_friendly.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.offer_friendly.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_offer_friendly_neutral",
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
                ["responseTemplateID"] = "semantic.social.offer_friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/offers.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. I'll keep that in mind.",
                            },
                            ["TL"] = {
                                "Salamat. Tatandaan ko iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you for the offer.",
                            },
                            ["TL"] = {
                                "Salamat sa alok mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I appreciate you offering. I'll let you know.",
                            },
                            ["TL"] = {
                                "Salamat sa pag-alok. Sasabihan kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Good to know. I might take you up on that.",
                            },
                            ["TL"] = {
                                "Mabuting malaman. Baka tanggapin ko 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. That's a helpful gesture.",
                            },
                            ["TL"] = {
                                "Salamat. Nakatutulong ang malasakit mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll consider it. Thanks.",
                            },
                            ["TL"] = {
                                "Isasaalang-alang ko. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Much obliged for the thought.",
                            },
                            ["TL"] = {
                                "Maraming salamat sa magandang kaisipan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate the option. Thank you.",
                            },
                            ["TL"] = {
                                "Salamat sa pagbibigay ng opsyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks. We'll see how the day goes.",
                            },
                            ["TL"] = {
                                "Salamat. Tingnan natin ang takbo ng araw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Kind offer. Thank you.",
                            },
                            ["TL"] = {
                                "Mabuting alok. Salamat.",
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
        ["sourceShard"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
