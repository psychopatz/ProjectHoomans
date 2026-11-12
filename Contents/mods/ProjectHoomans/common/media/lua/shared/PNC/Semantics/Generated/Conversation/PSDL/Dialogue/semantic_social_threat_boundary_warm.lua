-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.threat_boundary.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.threat_boundary.warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[23]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_threat_boundary_warm",
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
                ["responseTemplateID"] = "semantic.social.threat_boundary",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/threats.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hey, please, don't do this. Step back.",
                            },
                            ["TL"] = {
                                "Huy, pakiusap, huwag mong gawin 'to. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "We don't need blood spilled today. Put it down.",
                            },
                            ["TL"] = {
                                "Di natin kailangang magpadanak ng dugo ngayon. Ibaba mo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Listen to reason, friend. Step away before someone gets hurt.",
                            },
                            ["TL"] = {
                                "Makinig ka sa katwiran, kaibigan. Lumayo ka bago may masaktan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "I don't want to hurt you. Please, back off.",
                            },
                            ["TL"] = {
                                "Ayaw kitang saktan. Pakiusap, umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Don't throw your life away over this. Stand down.",
                            },
                            ["TL"] = {
                                "Huwag mong itapon ang buhay mo dahil dito. Ibaba ang armas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "We can still walk away peacefully. Step back.",
                            },
                            ["TL"] = {
                                "Maaari pa tayong lumayo nang payapa. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Take a breath and think about what you're doing. Back up.",
                            },
                            ["TL"] = {
                                "Huminga ka muna at isipin ang ginagawa mo. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "I value your life, but I will protect mine. Please stop.",
                            },
                            ["TL"] = {
                                "Mahalaga ang buhay mo, pero poprotektahan ko ang akin. Pakiusap tigil.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Don't make me do something we'll both regret. Step back.",
                            },
                            ["TL"] = {
                                "Huwag mo akong piliting gumawa ng pagsisisihan natin. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "We're both survivors. Let's keep it that way. Back down.",
                            },
                            ["TL"] = {
                                "Pareho tayong nakaligtas. Panatilihin nating ganoon. Huminahon ka.",
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
        ["sourceShard"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
