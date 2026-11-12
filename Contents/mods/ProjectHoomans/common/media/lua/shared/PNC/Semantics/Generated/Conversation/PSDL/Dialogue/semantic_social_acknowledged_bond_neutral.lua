-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.bond_neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.bond_neutral",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_acknowledged_bond_neutral",
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
                ["responseTemplateID"] = "semantic.social.acknowledged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/social/reactions/acknowledgement.json",
                ["style"] = "bond_neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "bond_neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "%s, all right.",
                            },
                            ["TL"] = {
                                "%s, sige.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "%s, understood.",
                            },
                            ["TL"] = {
                                "%s, naiintindihan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I hear what you're saying.",
                            },
                            ["TL"] = {
                                "%s, naririnig ko ang sinasabi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "%s, got it. Makes sense.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko. May katuturan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "%s, sounds reasonable.",
                            },
                            ["TL"] = {
                                "%s, mukhang makatwiran.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "%s, message received.",
                            },
                            ["TL"] = {
                                "%s, natanggap ang mensahe.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "%s, fair enough. We'll roll with that.",
                            },
                            ["TL"] = {
                                "%s, may punto ka. Susundin natin 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "%s, acknowledged. Let's get to work.",
                            },
                            ["TL"] = {
                                "%s, naintindihan. Simulan na natin ang trabaho.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "%s, point taken.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko ang punto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "%s, right with you on that.",
                            },
                            ["TL"] = {
                                "%s, sang-ayon ako sa 'yo riyan.",
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
