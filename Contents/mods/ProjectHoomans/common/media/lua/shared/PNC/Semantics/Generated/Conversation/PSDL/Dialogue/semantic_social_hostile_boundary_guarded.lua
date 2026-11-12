-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.hostile_boundary.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_boundary.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[24]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_hostile_boundary_guarded",
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
                ["responseTemplateID"] = "semantic.social.hostile_boundary",
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
                                "Don't talk to me like that.",
                            },
                            ["TL"] = {
                                "Huwag mo akong kausapin nang ganyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Check yourself before you speak to me again.",
                            },
                            ["TL"] = {
                                "Pagsabihan mo ang sarili mo bago ka makipag-usap sa 'kin ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "You're stepping way out of line.",
                            },
                            ["TL"] = {
                                "Sumusobra ka na sa linya.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Mind your mouth around me.",
                            },
                            ["TL"] = {
                                "Bantayan mo ang bibig mo sa harap ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "I don't take disrespect from anyone.",
                            },
                            ["TL"] = {
                                "Hindi ako pumapayag na bastusin ng kahit sino.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "You cross that boundary again and see what happens.",
                            },
                            ["TL"] = {
                                "Tawirin mo ulit ang hangganang 'yan at tingnan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Watch how you address me.",
                            },
                            ["TL"] = {
                                "Bantayan mo kung paano mo ako kausapin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your tone in check.",
                            },
                            ["TL"] = {
                                "Ayusin mo ang tono mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "You are playing with a short fuse.",
                            },
                            ["TL"] = {
                                "Naglalaro ka sa maikling mitsa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Back off that attitude.",
                            },
                            ["TL"] = {
                                "Alisin mo ang ganyang ugali.",
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
        ["sourceShard"] = "psdl/dialogue/social_reactions_ack_dispute.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
