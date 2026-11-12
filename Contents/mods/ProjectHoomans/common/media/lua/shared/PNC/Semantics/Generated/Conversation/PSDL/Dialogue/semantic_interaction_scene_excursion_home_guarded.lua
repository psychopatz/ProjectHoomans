-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_home.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_home.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_excursion_home_guarded",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_home",
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
                                "We're back. Check in and settle down.",
                            },
                            ["TL"] = {
                                "Nakabalik na tayo. Mag-check in at magpahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Bar the doors immediately. Don't let anything follow us in.",
                            },
                            ["TL"] = {
                                "Kandadohin ang pinto agad. Huwag magpapasok ng kahit ano.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Inventory the gear right now before anything goes missing.",
                            },
                            ["TL"] = {
                                "Ilista ang mga gamit ngayon bago may mawala.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Inside the fence, but don't drop your guard completely.",
                            },
                            ["TL"] = {
                                "Nasa loob na ng bakod, pero huwag ibaba nang buo ang bantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Check the perimeter sentries. Make sure the camp wasn't breached.",
                            },
                            ["TL"] = {
                                "Tingnan ang mga nagbabantay. Tiyaking di pinasok ang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Secure the locks. Then we tally our supplies.",
                            },
                            ["TL"] = {
                                "I-lock ang pinto. Pagkatapos bilangin ang mga gamit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "We're back. Did anyone get bitten? Speak up now.",
                            },
                            ["TL"] = {
                                "Nakabalik na. May nakagat ba? Magsalita ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Drop the backpacks in the storeroom. Keep weapons loaded.",
                            },
                            ["TL"] = {
                                "Ibaba ang bag sa bodega. Panatilihing may karga ang armas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Good, we're inside. Keep quiet so we don't draw strays.",
                            },
                            ["TL"] = {
                                "Mabuti, nasa loob na. Manahimik para di maakit ang mga patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Back inside the wire. Rest, but be ready to mobilize.",
                            },
                            ["TL"] = {
                                "Nasa loob na ng alambre. Magpahinga, pero laging handa.",
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
