-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.offer_friendly.bond_warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.offer_friendly.bond_warm",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_offer_friendly_bond_warm",
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
                ["style"] = "bond_warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "bond_warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "%s, thank you. I'll keep it in mind.",
                            },
                            ["TL"] = {
                                "%s, salamat. Tatandaan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "%s, you're always so generous. Thank you, friend.",
                            },
                            ["TL"] = {
                                "%s, napakabait mo talaga palagi. Salamat, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "%s, that means a lot coming from you. Thanks!",
                            },
                            ["TL"] = {
                                "%s, malaking bagay 'yan galing sa 'yo. Salamat!",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I truly appreciate the gesture. You're great.",
                            },
                            ["TL"] = {
                                "%s, talagang pinahahalagahan ko ang malasakit mo. Napakagaling mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "%s, you don't have to share, but thank you so much.",
                            },
                            ["TL"] = {
                                "%s, di mo kailangang magbahagi, pero maraming salamat talaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "%s, thanks! It's rare to find such kindness out here.",
                            },
                            ["TL"] = {
                                "%s, salamat! Bihira ang ganitong kabaitan dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "%s, warm thanks. We always take care of our own.",
                            },
                            ["TL"] = {
                                "%s, taos-pusong pasasalamat. Inaalagaan natin ang kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "%s, that touches my heart. Thank you, partner.",
                            },
                            ["TL"] = {
                                "%s, tumatagos sa puso ko 'yan. Salamat, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "%s, you're a lifesaver. I appreciate you.",
                            },
                            ["TL"] = {
                                "%s, tagapagligtas ka. Salamat sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "%s, thanks a million! I'll return the favor.",
                            },
                            ["TL"] = {
                                "%s, milyong salamat! Babalikan ko ang pabor na 'to.",
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
