-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.hostile_withdrawn.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_withdrawn.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_hostile_withdrawn_guarded",
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
                ["responseTemplateID"] = "semantic.social.hostile_withdrawn",
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
                                "Leave me alone. Now.",
                            },
                            ["TL"] = {
                                "Iwan mo ako. Ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Get out of my sight.",
                            },
                            ["TL"] = {
                                "Umalis ka sa paningin ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Don't come near me.",
                            },
                            ["TL"] = {
                                "Huwag kang lalapit sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I have nothing to say to you. Go.",
                            },
                            ["TL"] = {
                                "Wala akong sasabihin sa 'yo. Umalis ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Walk away while you still can.",
                            },
                            ["TL"] = {
                                "Lumakad ka palayo habang kaya mo pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "Leave me be.",
                            },
                            ["TL"] = {
                                "Hayaan mo akong mag-isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm done with you. Get lost.",
                            },
                            ["TL"] = {
                                "Tapos na ako sa 'yo. Lumayas ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Stay away from my corner.",
                            },
                            ["TL"] = {
                                "Huwag kang pupunta sa pwesto ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Leave. Immediately.",
                            },
                            ["TL"] = {
                                "Umalis ka. Ngayon din.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Don't speak to me.",
                            },
                            ["TL"] = {
                                "Huwag mo akong kausapin.",
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
