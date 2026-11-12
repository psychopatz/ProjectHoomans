-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_answer.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_answer.warm",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[25]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_grounded_news_answer_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "I wish I knew more, but that is what I can confirm.",
                            },
                            ["TL"] = {
                                "Sana mas marami akong alam, pero iyan ang makukumpirma ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "That's all I have for you right now, friend, but I'll keep asking.",
                            },
                            ["TL"] = {
                                "Iyan lang muna, kaibigan, pero patuloy akong magtatanong.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "I wanted to share everything I knew to keep you safe.",
                            },
                            ["TL"] = {
                                "Gusto kong ibahagi ang lahat para manatili kang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "If any more news comes my way, you'll be the first I tell.",
                            },
                            ["TL"] = {
                                "Kapag may bagong balita, ikaw ang una kong sasabihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hope that helps you out today, partner.",
                            },
                            ["TL"] = {
                                "Sana makatulong 'yan sa 'yo ngayong araw, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "That's the whole story as far as I've been told.",
                            },
                            ["TL"] = {
                                "Iyan ang buong kuwento ayon sa sinabi sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm glad I could pass that along to you.",
                            },
                            ["TL"] = {
                                "Mabuti at naipasa ko sa 'yo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "That's what we have to work with for now, friend.",
                            },
                            ["TL"] = {
                                "Iyan ang hawak natin sa ngayon, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll keep my ears open for you.",
                            },
                            ["TL"] = {
                                "Bukas ang tainga ko para sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "That's everything for now. Take good care of yourself.",
                            },
                            ["TL"] = {
                                "Iyan ang lahat sa ngayon. Ingatan mo ang sarili mo.",
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
