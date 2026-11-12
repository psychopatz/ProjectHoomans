-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.grounded_news_answer.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.grounded_news_answer.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[27]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_grounded_news_answer_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Nothing else I can verify yet.",
                            },
                            ["TL"] = {
                                "Wala pa akong ibang mapapatunayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I don't deal in rumors. That's the only confirmed piece.",
                            },
                            ["TL"] = {
                                "Di ako nakikipagtsismisan. Iyan lang ang kumpirmado.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Don't press for details I can't back up.",
                            },
                            ["TL"] = {
                                "Huwag kang maghanap ng detalyeng di ko mapatutunayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "That's the extent of it. Keep it between us.",
                            },
                            ["TL"] = {
                                "Hanggang diyan lang. Sa ating dalawa lang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I won't guess about the rest. Stick to the facts.",
                            },
                            ["TL"] = {
                                "Hindi ako manghuhula. Manatili sa katotohanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "That is all you need to know for now.",
                            },
                            ["TL"] = {
                                "Iyan lang ang kailangan mong malaman sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Anything beyond that is dangerous speculation.",
                            },
                            ["TL"] = {
                                "Anuman higit diyan ay mapanganib na haka-haka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "I've verified that much. Nothing more to say.",
                            },
                            ["TL"] = {
                                "Iyan lang ang nakumpirma ko. Wala nang dapat sabihin pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Take that information and plan accordingly.",
                            },
                            ["TL"] = {
                                "Kunin ang balitang 'yan at magplano nang maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "That's all that's confirmed. Watch your step.",
                            },
                            ["TL"] = {
                                "Iyan lang ang tiyak. Mag-ingat ka sa hakbang mo.",
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
