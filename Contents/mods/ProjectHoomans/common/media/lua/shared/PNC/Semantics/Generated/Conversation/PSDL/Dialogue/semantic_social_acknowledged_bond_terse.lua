-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.bond_terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.bond_terse",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_acknowledged_bond_terse",
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
                ["style"] = "bond_terse",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "bond_terse.01",
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
                        ["id"] = "bond_terse.02",
                        ["text"] = {
                            ["EN"] = {
                                "%s, understood.",
                            },
                            ["TL"] = {
                                "%s, naintindihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.03",
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
                        ["id"] = "bond_terse.04",
                        ["text"] = {
                            ["EN"] = {
                                "%s, heard.",
                            },
                            ["TL"] = {
                                "%s, narinig ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.05",
                        ["text"] = {
                            ["EN"] = {
                                "%s, clear.",
                            },
                            ["TL"] = {
                                "%s, malinaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.06",
                        ["text"] = {
                            ["EN"] = {
                                "%s, right.",
                            },
                            ["TL"] = {
                                "%s, tama.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.07",
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
                                "%s, agreed.",
                            },
                            ["TL"] = {
                                "%s, sang-ayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.10",
                        ["text"] = {
                            ["EN"] = {
                                "%s, done.",
                            },
                            ["TL"] = {
                                "%s, tapos.",
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
