-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.hostile_stressed.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_stressed.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_hostile_stressed_guarded",
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
                ["responseTemplateID"] = "semantic.social.hostile_stressed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/hostile.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's enough. Back away.",
                            },
                            ["TL"] = {
                                "Tama na. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Get back before I make you.",
                            },
                            ["TL"] = {
                                "Umatras ka bago pa kita pilitin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Give me space right now.",
                            },
                            ["TL"] = {
                                "Bigyan mo ako ng puwang ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Step back and keep your hands where I can see them.",
                            },
                            ["TL"] = {
                                "Umatras ka at panatilihin ang kamay sa kita ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I am armed and exhausted. Back off.",
                            },
                            ["TL"] = {
                                "May armas ako at pagod na. Lumayo ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Back away from me immediately.",
                            },
                            ["TL"] = {
                                "Lumayo ka sa akin agad-agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Don't crowd me while my nerves are on edge.",
                            },
                            ["TL"] = {
                                "Huwag mo akong dikitan habang tensiyonado ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Move back now.",
                            },
                            ["TL"] = {
                                "Umatras ka ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not warning you again. Step back.",
                            },
                            ["TL"] = {
                                "Hindi na kita babalaan ulit. Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stay five paces away from me.",
                            },
                            ["TL"] = {
                                "Manatili kang limang hakbang ang layo sa akin.",
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
