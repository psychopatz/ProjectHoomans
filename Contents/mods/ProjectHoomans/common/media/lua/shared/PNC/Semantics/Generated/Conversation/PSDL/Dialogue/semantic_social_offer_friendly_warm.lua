-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.offer_friendly.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.offer_friendly.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_offer_friendly_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you, I appreciate the offer.",
                            },
                            ["TL"] = {
                                "Salamat, pinahahalagahan ko ang alok mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "That is so kind of you! Thank you so much.",
                            },
                            ["TL"] = {
                                "Napakabait mo naman! Maraming-maraming salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm grateful for that. You're a true friend.",
                            },
                            ["TL"] = {
                                "Nagpapasalamat ako riyan. Tunay kang kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "That makes life a little easier out here. Thanks!",
                            },
                            ["TL"] = {
                                "Gumagaan ang buhay rito dahil diyan. Salamat!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Always generous. Thank you, partner.",
                            },
                            ["TL"] = {
                                "Laging bukas-palad. Salamat, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you! I won't forget your kindness.",
                            },
                            ["TL"] = {
                                "Salamat! Hindi ko malilimutan ang kabaitan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "You didn't have to, but thank you from the bottom of my heart.",
                            },
                            ["TL"] = {
                                "Hindi mo naman kailangang gawin, pero salamat mula sa puso.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "That's wonderful of you. Thank you!",
                            },
                            ["TL"] = {
                                "Napakaganda ng ginawa mo. Salamat!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate you so much. Let me return the favor soon.",
                            },
                            ["TL"] = {
                                "Salamat nang marami. Hayaan mong masuklian ko 'to agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thank you, friend. We look after one another.",
                            },
                            ["TL"] = {
                                "Salamat, kaibigan. Nag-aalagaan tayo rito.",
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
