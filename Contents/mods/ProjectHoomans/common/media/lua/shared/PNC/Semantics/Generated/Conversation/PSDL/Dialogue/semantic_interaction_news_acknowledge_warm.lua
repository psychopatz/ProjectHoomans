-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_news",
        ["id"] = "semantic.interaction.news.acknowledge.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.news.acknowledge.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_news.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_news_acknowledge_warm",
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
                ["responseTemplateID"] = "semantic.interaction.news.acknowledge",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/news/acknowledge.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for telling me. I'll keep that in mind.",
                            },
                            ["TL"] = {
                                "Salamat sa pagsabi. Tatandaan ko iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's huge news, friend! Thank you for sharing.",
                            },
                            ["TL"] = {
                                "Napakalaking balita niyan, kaibigan! Salamat sa pagbabahagi.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Always glad to know you're looking out for me with news like this.",
                            },
                            ["TL"] = {
                                "Lagi akong masaya na binabantayan mo ako sa mga ganitong balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "You have great sources! Thanks a ton.",
                            },
                            ["TL"] = {
                                "Napakagaling ng mga pinagkukunan mo! Maraming salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "I really appreciate you giving me the heads up first.",
                            },
                            ["TL"] = {
                                "Talagang pinahahalagahan ko na ako ang unang pinaalalahanan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Good news is worth its weight in gold out here. Thanks!",
                            },
                            ["TL"] = {
                                "Ang magandang balita ay ginto ang halaga rito. Salamat!",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for sharing that with me. It gives me hope.",
                            },
                            ["TL"] = {
                                "Salamat sa pagbabahagi niyan sa akin. Nagbibigay ito ng pag-asa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'm relieved to hear that. Thank you so much, partner.",
                            },
                            ["TL"] = {
                                "Nakahinga ako nang maluwag nang marinig 'yan. Salamat nang marami, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "That's fantastic information. Appreciate you keeping us safe.",
                            },
                            ["TL"] = {
                                "Napakagandang impormasyon. Salamat sa pag-iingat sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks! Let's make sure the others hear this too.",
                            },
                            ["TL"] = {
                                "Salamat! Tiyakin nating marinig din ito ng iba.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
