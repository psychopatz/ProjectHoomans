-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.hostile_short.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.hostile_short.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_hostile_short_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Watch your mouth. Now.",
                            },
                            ["TL"] = {
                                "Bantayan mo ang pananalita mo. Ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "Shut your mouth before I shut it for you.",
                            },
                            ["TL"] = {
                                "Itikom mo ang bibig mo bago ko pa itikom 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "You're pushing me. Stop.",
                            },
                            ["TL"] = {
                                "Sinasagad mo ako. Tigil.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "One more word out of you.",
                            },
                            ["TL"] = {
                                "Isa pang salita mula sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Mind yourself right now.",
                            },
                            ["TL"] = {
                                "Bantayan mo ang kilos mo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "You're testing the wrong survivor.",
                            },
                            ["TL"] = {
                                "Maling tao ang sinusubukan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Quiet. Before things get violent.",
                            },
                            ["TL"] = {
                                "Tahimik. Bago maging bayolente ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "You want trouble? Keep talking.",
                            },
                            ["TL"] = {
                                "Gusto mo ng gulo? Sige, magsalita ka pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Hold your tongue.",
                            },
                            ["TL"] = {
                                "Pigilan mo ang dila mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Bite your tongue now.",
                            },
                            ["TL"] = {
                                "Kagatin mo ang dila mo ngayon.",
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
