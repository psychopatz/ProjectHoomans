-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_share.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_share.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[23]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_grounded_news_share_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I have something I can confirm.",
                            },
                            ["TL"] = {
                                "May bagay akong makukumpirma.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I have verified intel, but keep it quiet.",
                            },
                            ["TL"] = {
                                "May napatunayan akong impormasyon, pero panatilihing lihim.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Listen close. I don't want everyone overhearing this.",
                            },
                            ["TL"] = {
                                "Makinig nang mabuti. Ayokong marinig ito ng lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm sharing this with you because you need to know the risks.",
                            },
                            ["TL"] = {
                                "Ibinabahagi ko ito dahil kailangan mong malaman ang panganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "News from the perimeter. Don't go spreading it wildly.",
                            },
                            ["TL"] = {
                                "Balita mula sa paligid. Huwag mong ikalat kung saan-saan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I verified this rumor myself. Take it seriously.",
                            },
                            ["TL"] = {
                                "Kinumpirma ko ang balitang ito mismo. Seryosohin mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Careful who you repeat this to, but here's the situation.",
                            },
                            ["TL"] = {
                                "Mag-ingat kung kanino mo sasabihin, pero ito ang kalagayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "I have confirmed facts about what happened out there.",
                            },
                            ["TL"] = {
                                "May napatunayan akong katotohanan sa nangyari sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your voice low. Here's what I confirmed.",
                            },
                            ["TL"] = {
                                "Hinaan ang boses mo. Ito ang nakumpirma ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Actionable intel. Use it to protect yourself.",
                            },
                            ["TL"] = {
                                "Magagamit na impormasyon. Gamitin para protektahan ang sarili.",
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
