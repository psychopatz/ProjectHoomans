-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_news",
        ["id"] = "semantic.interaction.news.acknowledge.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.news.acknowledge.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_news.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_news_acknowledge_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll keep it in mind.",
                            },
                            ["TL"] = {
                                "Tatandaan ko iyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Where did you hear that from?",
                            },
                            ["TL"] = {
                                "Saan mo narinig ang balitang 'yan?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll believe it when I see it with my own eyes.",
                            },
                            ["TL"] = {
                                "Maniwala lang ako kapag nakita ko na ng sarili kong mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Rumors can get people killed out here. Be sure of your facts.",
                            },
                            ["TL"] = {
                                "Ang tsismis ay nakamamatay dito. Tiyakin mo ang katotohanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Noted, but I'll verify that myself.",
                            },
                            ["TL"] = {
                                "Tala ko na, pero kumpirmahin ko muna sa sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Could be a setup. Don't act on rumors too quickly.",
                            },
                            ["TL"] = {
                                "Baka bitag 'yan. Huwag kumilos sa sabi-sabi nang padalos-dalos.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Who gave you that information?",
                            },
                            ["TL"] = {
                                "Sinong nagbigay sa 'yo ng impormasyong 'yan?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll take it under advisement, but keep my distance.",
                            },
                            ["TL"] = {
                                "Isasaalang-alang ko, pero magmamasid pa rin ako mula sa malayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Don't spread that around until we know it's solid.",
                            },
                            ["TL"] = {
                                "Huwag mong ikalat 'yan hangga't di tiyak na totoo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Heard. I'll watch for confirming signs.",
                            },
                            ["TL"] = {
                                "Narinig ko. Magmamasid ako ng mga patunay.",
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
