-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_share.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_share.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[21]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_grounded_news_share_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I thought you should hear what I learned.",
                            },
                            ["TL"] = {
                                "Naisip kong dapat mong marinig ang nalaman ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hey friend, I found out something that might help us.",
                            },
                            ["TL"] = {
                                "Huy kaibigan, may nalaman akong makatutulong sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I wanted to make sure you were in the loop on this news.",
                            },
                            ["TL"] = {
                                "Gusto kong tiyakin na may alam ka sa balitang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got some good intel to share with you, partner.",
                            },
                            ["TL"] = {
                                "May magandang balita akong ibabahagi sa 'yo, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Always looking out for you—listen to what I heard.",
                            },
                            ["TL"] = {
                                "Lagi kitang iniisip—makinig ka sa narinig ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Thought of you as soon as I heard this update.",
                            },
                            ["TL"] = {
                                "Ikaw agad ang naisip ko nang marinig ko ang balitang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Come here, I have news that might make things easier.",
                            },
                            ["TL"] = {
                                "Halika rito, may balita ako na magpapagaan ng sitwasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to share this bit of hope with you today.",
                            },
                            ["TL"] = {
                                "Masayang ibahagi ang kaunting pag-asang ito sa 'yo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Listen up, friend. This could keep us safer.",
                            },
                            ["TL"] = {
                                "Makinig ka, kaibigan. Mas makapagpapanatiling ligtas ito sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "I wanted you to hear this first from me.",
                            },
                            ["TL"] = {
                                "Gusto kong sa akin mo unang marinig ito.",
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
