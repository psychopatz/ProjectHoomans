-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_news",
        ["id"] = "semantic.interaction.news.acknowledge.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.news.acknowledge.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_news.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_news_acknowledge_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's good to know.",
                            },
                            ["TL"] = {
                                "Mabuting malaman iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Appreciate the update.",
                            },
                            ["TL"] = {
                                "Salamat sa balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll keep that intelligence in mind.",
                            },
                            ["TL"] = {
                                "Isasaisip ko ang impormasyong iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Good to have fresh news from the area.",
                            },
                            ["TL"] = {
                                "Mabuting makatanggap ng bagong balita mula sa lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for passing that along.",
                            },
                            ["TL"] = {
                                "Salamat sa pagpasa niyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. That changes how we look at the sector.",
                            },
                            ["TL"] = {
                                "Naintindihan. Binabago niyan ang pananaw natin sa lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Good information. We'll plan around it.",
                            },
                            ["TL"] = {
                                "Magandang impormasyon. Magpaplano tayo batay diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. Reliable news is hard to come by.",
                            },
                            ["TL"] = {
                                "Tala ko na. Mahirap makahanap ng maaasahang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks for keeping me informed.",
                            },
                            ["TL"] = {
                                "Salamat sa pagpapanatili sa aking may alam.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "That helps clear up a few rumors. Thanks.",
                            },
                            ["TL"] = {
                                "Nakatulong 'yan para maalis ang ilang sabi-sabi. Salamat.",
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
