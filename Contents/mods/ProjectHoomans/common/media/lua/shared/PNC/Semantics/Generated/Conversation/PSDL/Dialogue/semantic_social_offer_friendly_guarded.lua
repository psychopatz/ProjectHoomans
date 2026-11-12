-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.offer_friendly.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.offer_friendly.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_offer_friendly_guarded",
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
                ["responseTemplateID"] = "semantic.social.offer_friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/offers.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "No thanks. I can handle it.",
                            },
                            ["TL"] = {
                                "Hindi salamat. Kaya ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I don't need hand-outs. Thanks anyway.",
                            },
                            ["TL"] = {
                                "Di ko kailangan ng limos. Salamat pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your supplies. You'll need them more than me.",
                            },
                            ["TL"] = {
                                "Itago mo ang gamit mo. Mas kailangan mo 'yan kaysa sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "I prefer to rely on myself, but thanks.",
                            },
                            ["TL"] = {
                                "Mas gusto kong umasa sa sarili ko, pero salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "No thank you. What's the catch?",
                            },
                            ["TL"] = {
                                "Hindi salamat. May kapalit ba 'yan?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm managing fine on my own.",
                            },
                            ["TL"] = {
                                "Maayos ang pamamahala ko sa sarili ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Pass. I carry what I need.",
                            },
                            ["TL"] = {
                                "Tatanggihan ko. Dala ko ang kailangan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Thanks, but no. Save it.",
                            },
                            ["TL"] = {
                                "Salamat, pero hindi. Itabi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll take care of my own needs.",
                            },
                            ["TL"] = {
                                "Ako na ang bahala sa mga pangangailangan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Not interested, but thanks for offering.",
                            },
                            ["TL"] = {
                                "Di ako interesado, pero salamat sa pag-alok.",
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
