-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_share.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_share.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_grounded_news_share_neutral",
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
                ["responseTemplateID"] = "semantic.interaction.scene.grounded_news_share",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/grounded_news.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I heard something worth passing on.",
                            },
                            ["TL"] = {
                                "May narinig akong mahalagang ipasa sa iyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Got an update on what's happening nearby.",
                            },
                            ["TL"] = {
                                "May balita ako sa mga nangyayari sa paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "There's fresh news from the neighboring zone.",
                            },
                            ["TL"] = {
                                "May sariwang balita mula sa kalapit na lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I picked up some information you should know about.",
                            },
                            ["TL"] = {
                                "May nakuha akong impormasyon na dapat mong malaman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Heads up: I heard a report about conditions outside.",
                            },
                            ["TL"] = {
                                "Makinig ka: may narinig akong ulat tungkol sa kalagayan sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Passing along some intelligence I gathered.",
                            },
                            ["TL"] = {
                                "Ipinapasa ko ang ilang impormasyong nakalap ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Here's what I've learned from other travelers.",
                            },
                            ["TL"] = {
                                "Ito ang nalaman ko mula sa ibang manlalakbay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "You might want to hear this latest report.",
                            },
                            ["TL"] = {
                                "Baka gusto mong marinig itong pinakahuling balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I have some verified information to share.",
                            },
                            ["TL"] = {
                                "May napatunayan akong impormasyon na ibabahagi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Listen to this news before you head out.",
                            },
                            ["TL"] = {
                                "Pakinggan mo itong balita bago ka lumabas.",
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
        ["sourceShard"] = "psdl/dialogue/social_interaction_scene_travel_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
