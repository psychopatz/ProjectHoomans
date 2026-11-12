-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_hostile_offer_threat",
        ["id"] = "semantic.social.offer_friendly.bond_neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.offer_friendly.bond_neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_hostile_offer_threat.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_offer_friendly_bond_neutral",
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
                ["style"] = "bond_neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "bond_neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "%s, that's kind of you. I'll keep it in mind.",
                            },
                            ["TL"] = {
                                "%s, mabuti iyon. Tatandaan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "%s, thanks for the offer. I'll think about it.",
                            },
                            ["TL"] = {
                                "%s, salamat sa alok. Pag-iisipan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I appreciate the offer. Let's see how things go.",
                            },
                            ["TL"] = {
                                "%s, salamat sa alok. Tingnan natin kung ano ang mangyayari.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "%s, good to know. Thank you.",
                            },
                            ["TL"] = {
                                "%s, mabuting malaman. Maraming salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I might take you up on that later.",
                            },
                            ["TL"] = {
                                "%s, baka tanggapin ko 'yan mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "%s, thanks for putting that on the table.",
                            },
                            ["TL"] = {
                                "%s, salamat sa paglalatag niyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "%s, that's helpful. Thanks.",
                            },
                            ["TL"] = {
                                "%s, makatutulong 'yan. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "%s, generous offer. Appreciate it.",
                            },
                            ["TL"] = {
                                "%s, bukas-palad na alok. Salamat.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "%s, noted with thanks. I'll let you know.",
                            },
                            ["TL"] = {
                                "%s, tala ko na kalakip ang pasasalamat. Sasabihan kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "%s, thanks for looking out for me.",
                            },
                            ["TL"] = {
                                "%s, salamat sa pag-alaga sa akin.",
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
