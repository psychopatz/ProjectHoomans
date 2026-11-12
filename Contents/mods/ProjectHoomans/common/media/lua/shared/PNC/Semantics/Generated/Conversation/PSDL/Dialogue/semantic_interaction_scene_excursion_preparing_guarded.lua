-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_preparing.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_preparing.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_excursion_preparing_guarded",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_preparing",
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
                                "Prep first. We move when everyone's ready.",
                            },
                            ["TL"] = {
                                "Maghanda muna. Aalis tayo kapag handa na ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "If you forget something vital out there, nobody is turning back for you.",
                            },
                            ["TL"] = {
                                "Kapag may naiwan kang mahalaga, walang babalik para sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Check your ammunition count twice. No excuses.",
                            },
                            ["TL"] = {
                                "Bilangin ang bala mo nang dalawang beses. Walang palusot.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Sharpen your blade now. We don't stop for maintenance in the field.",
                            },
                            ["TL"] = {
                                "Hasiin ang talim mo ngayon. Walang hinto para magkumpuni sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Pack light, pack lethal. Don't carry useless junk.",
                            },
                            ["TL"] = {
                                "Magdala ng magaan at nakamamatay. Huwag magdala ng kalat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Inspect your boots. A twisted ankle out there is fatal.",
                            },
                            ["TL"] = {
                                "Suriin ang sapatos mo. Nakamamatay ang maipit ang paa sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Be completely ready before you step past that gate.",
                            },
                            ["TL"] = {
                                "Maging handang-handa bago lumabas sa tarangkahang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Check your medical supplies. You bleed, you fix it.",
                            },
                            ["TL"] = {
                                "Tingnan ang gamot mo. Kapag nagdugo ka, gamutin mo sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Preparing now. Stay disciplined once we cross the threshold.",
                            },
                            ["TL"] = {
                                "Naghahanda na. Maging disiplinado paglabas natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Lock and load. Don't slow the group down.",
                            },
                            ["TL"] = {
                                "Magkarga ng armas. Huwag mong pabagalin ang grupo.",
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
