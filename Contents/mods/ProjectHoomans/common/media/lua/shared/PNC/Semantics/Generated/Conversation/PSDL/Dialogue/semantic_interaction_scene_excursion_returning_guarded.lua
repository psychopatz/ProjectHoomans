-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_interaction_scene_travel_news",
        ["id"] = "semantic.interaction.scene.excursion_returning.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.scene.excursion_returning.guarded",
            ["sourcePath"] = "psdl/dialogue/social_interaction_scene_travel_news.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_scene_excursion_returning_guarded",
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
                ["responseTemplateID"] = "semantic.interaction.scene.excursion_returning",
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
                                "We're returning. Stay alert until we're home.",
                            },
                            ["TL"] = {
                                "Pabalik na tayo. Mag-ingat hanggang makauwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "The trip back is when most scavengers get ambushed. Watch the trees.",
                            },
                            ["TL"] = {
                                "Sa pagbalik karaniwang tinatambangan ang tao. Bantayan ang puno.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Don't let your guard down just because we're heading home.",
                            },
                            ["TL"] = {
                                "Huwag ibaba ang bantay dahil lang pauwi na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Check your rear. Make sure nothing is following our scent.",
                            },
                            ["TL"] = {
                                "Tingnan ang likod. Tiyaking walang sumusunod sa amoy natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Keep the haul hidden. We don't want to draw bandit eyes.",
                            },
                            ["TL"] = {
                                "Itago ang mga nakuha. Ayaw nating makahikayat ng magnanakaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Returning now. Speed up without making noise.",
                            },
                            ["TL"] = {
                                "Babalik na. Bilis-bilisan nang walang ginagawang ingay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "We're inbound. Stay ready to drop the bags and fight.",
                            },
                            ["TL"] = {
                                "Papasok na. Maging handang ibaba ang bag at lumaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Watch our backtrail. Stragglers could be tailing us.",
                            },
                            ["TL"] = {
                                "Bantayan ang dinaanan. Baka may sumusunod sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Almost at the gates, but keep checking corners.",
                            },
                            ["TL"] = {
                                "Malapit na sa tarangkahan, pero suriin pa rin ang mga kanto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Returning. No relaxing until the deadbolt is thrown.",
                            },
                            ["TL"] = {
                                "Pabalik na. Walang magpapahinga hangga't di nakakandado.",
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
