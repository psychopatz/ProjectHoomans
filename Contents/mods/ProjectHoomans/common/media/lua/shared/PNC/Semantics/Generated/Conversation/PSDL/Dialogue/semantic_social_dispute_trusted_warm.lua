-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.dispute_trusted.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.dispute_trusted.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_dispute_trusted_warm",
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
                ["responseTemplateID"] = "semantic.social.dispute_trusted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/disputes.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "You know I'd follow you through hell, but not into this.",
                            },
                            ["TL"] = {
                                "Alam mong sasamahan kita kahit saan, pero hindi sa bagay na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I love how bold you are, but this risk is too steep.",
                            },
                            ["TL"] = {
                                "Hanga ako sa tapang mo, pero masyadong mataas ang sugal na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Because I care about you, I have to say no to this.",
                            },
                            ["TL"] = {
                                "Dahil nagmamalasakit ako sa 'yo, kailangan kong tumanggi rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "We've kept each other alive this long. Trust me on this disagreement.",
                            },
                            ["TL"] = {
                                "Matagal na nating binubuhay ang isa't isa. Magtiwala ka sa pagtutol ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "You're my closest ally, so listen to my gut on this one.",
                            },
                            ["TL"] = {
                                "Pinakamalapit kitang kasama, kaya pakinggan mo ang kutob ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm telling you this because I want us both to live to see tomorrow.",
                            },
                            ["TL"] = {
                                "Sinasabi ko ito dahil gusto kong mabuhay tayong pareho bukas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "No matter what happens, we're solid. But I disagree here.",
                            },
                            ["TL"] = {
                                "Kahit anong mangyari, matibay tayo. Pero di ako sang-ayon dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Let's find a compromise that keeps both of us safe.",
                            },
                            ["TL"] = {
                                "Humanap tayo ng paraan na magpapanatiling ligtas sa ating dalawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I value our bond above any single disagreement.",
                            },
                            ["TL"] = {
                                "Mas mahalaga ang samahan natin kaysa sa anumang pagtatalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "We'll work it out together like we always do.",
                            },
                            ["TL"] = {
                                "Aayusin natin ito nang magkasama gaya ng dati.",
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
