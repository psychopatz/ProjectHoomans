-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.offer_friendly.bond_guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.offer_friendly.bond_guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_offer_friendly_bond_guarded",
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
                ["style"] = "bond_guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "bond_guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "%s, no thanks. I'll handle it.",
                            },
                            ["TL"] = {
                                "%s, hindi salamat. Ako na ang bahala.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I appreciate the thought, but I've got this.",
                            },
                            ["TL"] = {
                                "%s, salamat sa alok, pero kaya ko na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "%s, keep your supplies. I can manage.",
                            },
                            ["TL"] = {
                                "%s, itabi mo ang gamit mo. Kaya ko na.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "%s, no need. Save it for when we really need it.",
                            },
                            ["TL"] = {
                                "%s, di kailangan. Itabi mo kapag talagang kailangan na.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I'll pass for now, but thanks.",
                            },
                            ["TL"] = {
                                "%s, tatanggihan ko muna ngayon, pero salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "%s, thanks, but I don't need charity.",
                            },
                            ["TL"] = {
                                "%s, salamat, pero di ko kailangan ng limos.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I'm good on my own, thanks.",
                            },
                            ["TL"] = {
                                "%s, ayos lang ako mag-isa, salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "%s, hold onto that. You might need it more.",
                            },
                            ["TL"] = {
                                "%s, hawakan mo 'yan. Baka mas kailanganin mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "%s, no thanks. Let's stay focused.",
                            },
                            ["TL"] = {
                                "%s, hindi salamat. Manatili tayong nakapokus.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "%s, appreciated, but I prefer to carry my own weight.",
                            },
                            ["TL"] = {
                                "%s, salamat, pero mas gusto kong buhatin ang sarili ko.",
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
