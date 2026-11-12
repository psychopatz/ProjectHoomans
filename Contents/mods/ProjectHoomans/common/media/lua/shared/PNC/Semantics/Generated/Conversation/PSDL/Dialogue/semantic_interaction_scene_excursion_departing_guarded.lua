-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_departing.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_departing.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_excursion_departing_guarded",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_departing",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/interaction/scene/excursion.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "We're outbound. Keep the group tight.",
                            },
                            ["TL"] = {
                                "Papunta na tayo. Panatilihing dikit ang grupo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Crossing outside. Weapons ready, safety off.",
                            },
                            ["TL"] = {
                                "Lalabas na. Handa ang armas, alisin ang safety.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "No talking from here on out. Hand signals only.",
                            },
                            ["TL"] = {
                                "Walang magsasalita simula rito. Senyas-kamay lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Keep low and match my speed. Don't wander off.",
                            },
                            ["TL"] = {
                                "Yumuko at sumabay sa bilis ko. Huwag lalayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Scan your sectors continuously as we move.",
                            },
                            ["TL"] = {
                                "Bantayan ang pwesto niyo habang lumalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Outbound. If we take fire, dive for immediate cover.",
                            },
                            ["TL"] = {
                                "Palabas na. Kapag may nagpaputok, dapa agad sa kublihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Watch the tree line and rooftops. Moving out.",
                            },
                            ["TL"] = {
                                "Bantayan ang mga puno at bubong. Lakad na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Stay alert. The outside world is completely hostile.",
                            },
                            ["TL"] = {
                                "Maging alisto. Mapanganib ang buong mundo sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "We're moving. Anyone who strays gets left behind.",
                            },
                            ["TL"] = {
                                "Kumikilos na. Ang lumihis maiiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Formation tight. Moving into enemy territory.",
                            },
                            ["TL"] = {
                                "Mahigpit na pormasyon. Papatungo sa teritoryo ng kalaban.",
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
