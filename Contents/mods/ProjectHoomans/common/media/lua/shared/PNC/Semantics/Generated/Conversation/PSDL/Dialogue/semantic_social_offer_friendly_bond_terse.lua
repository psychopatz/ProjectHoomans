-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.offer_friendly.bond_terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.offer_friendly.bond_terse",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_offer_friendly_bond_terse",
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
                ["style"] = "bond_terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "bond_terse.01",
                        ["text"] = {
                            ["EN"] = {
                                "%s, thanks.",
                            },
                            ["TL"] = {
                                "%s, salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "%s, got it.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.03",
                        ["text"] = {
                            ["EN"] = {
                                "%s, noted.",
                            },
                            ["TL"] = {
                                "%s, tala ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I'm good.",
                            },
                            ["TL"] = {
                                "%s, ayos ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "%s, keep it.",
                            },
                            ["TL"] = {
                                "%s, itago mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "%s, pass.",
                            },
                            ["TL"] = {
                                "%s, tanggi muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.07",
                        ["text"] = {
                            ["EN"] = {
                                "%s, appreciated.",
                            },
                            ["TL"] = {
                                "%s, pinahahalagahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.08",
                        ["text"] = {
                            ["EN"] = {
                                "%s, good.",
                            },
                            ["TL"] = {
                                "%s, mabuti.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.09",
                        ["text"] = {
                            ["EN"] = {
                                "%s, later maybe.",
                            },
                            ["TL"] = {
                                "%s, baka mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "%s, thank you.",
                            },
                            ["TL"] = {
                                "%s, salamat sa 'yo.",
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
