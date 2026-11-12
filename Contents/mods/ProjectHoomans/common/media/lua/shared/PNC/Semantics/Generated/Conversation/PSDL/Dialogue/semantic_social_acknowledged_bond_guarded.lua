-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.bond_guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.bond_guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_acknowledged_bond_guarded",
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
                ["style"] = "bond_guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "bond_guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "%s, understood. We'll leave it there.",
                            },
                            ["TL"] = {
                                "%s, naiintindihan ko. Tama na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I hear you. Let's keep our heads on.",
                            },
                            ["TL"] = {
                                "%s, narinig kita. Mag-ingat na lang tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "%s, message received. Eyes open.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko ang mensahe. Buksan ang mga mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "%s, got it. No need to push further.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko. Hindi na kailangang magpumilit.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "%s, all right. Let's watch the perimeter.",
                            },
                            ["TL"] = {
                                "%s, sige. Bantayan natin ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "%s, acknowledged. We keep our guard up.",
                            },
                            ["TL"] = {
                                "%s, naintindihan. Huwag nating ibaba ang bantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "%s, I take your point. Let's be smart about this.",
                            },
                            ["TL"] = {
                                "%s, nakuha ko ang punto mo. Maging maingat tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "%s, clear enough. Leaving it at that.",
                            },
                            ["TL"] = {
                                "%s, sapat ang linaw. Iwan na natin doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "%s, noted. We stay sharp.",
                            },
                            ["TL"] = {
                                "%s, tala ko na. Manatili tayong alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "%s, fair enough. Let's move carefully.",
                            },
                            ["TL"] = {
                                "%s, makatwiran. Kumilos tayo nang maingat.",
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
