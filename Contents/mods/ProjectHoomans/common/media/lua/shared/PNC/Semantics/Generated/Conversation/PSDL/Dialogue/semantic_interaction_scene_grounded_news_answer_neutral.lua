-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_answer.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_answer.neutral",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[24]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_grounded_news_answer_neutral",
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
                ["responseTemplateID"] = "semantic.interaction.scene.grounded_news_answer",
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
                                "That is what I can confirm right now.",
                            },
                            ["TL"] = {
                                "Iyan ang makukumpirma ko sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's all the verified information I have.",
                            },
                            ["TL"] = {
                                "Iyan lang ang napatunayang impormasyong hawak ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That covers the extent of what I know.",
                            },
                            ["TL"] = {
                                "Iyan ang kabuuan ng nalalaman ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Beyond that, it's just guesswork.",
                            },
                            ["TL"] = {
                                "Higit pa riyan, hula-hula na lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "That's as much as I was able to find out.",
                            },
                            ["TL"] = {
                                "Iyan lang ang nagawa kong alamin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'll let you know if I hear anything more.",
                            },
                            ["TL"] = {
                                "Sasabihan kita kapag may narinig pa akong bago.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That's the factual picture for now.",
                            },
                            ["TL"] = {
                                "Iyan ang totoong larawan sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "That's what's solid. The rest is rumor.",
                            },
                            ["TL"] = {
                                "Iyan ang totoo. Tsismis na ang iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I've told you everything I can verify.",
                            },
                            ["TL"] = {
                                "Nasabi ko na ang lahat ng kaya kong kumpirmahin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "That's the report as it stands.",
                            },
                            ["TL"] = {
                                "Iyan ang ulat sa kasalukuyan.",
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
