-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.hostile_short.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_short.neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_hostile_short_neutral",
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
                ["responseTemplateID"] = "semantic.social.hostile_short",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/hostile.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Watch your language.",
                            },
                            ["TL"] = {
                                "Bantayan mo ang pananalita mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That kind of talk is dangerous here.",
                            },
                            ["TL"] = {
                                "Mapanganib ang ganyang salita rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your words civil.",
                            },
                            ["TL"] = {
                                "Panatilihing maayos ang mga salita mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'm warning you to calm down.",
                            },
                            ["TL"] = {
                                "Binabalaan kitang kumalma.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Don't escalate this situation.",
                            },
                            ["TL"] = {
                                "Huwag mong palalain ang sitwasyong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Control your temper.",
                            },
                            ["TL"] = {
                                "Pigilan mo ang init ng ulo mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "There's no place for that attitude here.",
                            },
                            ["TL"] = {
                                "Walang puwang ang ganyang asal dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Watch your mouth and think before you speak.",
                            },
                            ["TL"] = {
                                "Ingatan ang bibig at mag-isip bago magsalita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "You need to rein that in.",
                            },
                            ["TL"] = {
                                "Kailangan mong kontrolin 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Keep it civil or step away.",
                            },
                            ["TL"] = {
                                "Maging maayos ka o lumayo ka na.",
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
