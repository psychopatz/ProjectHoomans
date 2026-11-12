-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_reactions_ack_dispute",
        ["id"] = "semantic.social.acknowledged.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.social.acknowledged.guarded",
            ["sourcePath"] = "psdl/dialogue/social_reactions_ack_dispute.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_social_acknowledged_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. We'll leave it there.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Tama na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["text"] = {
                            ["EN"] = {
                                "I hear you. Don't press it any further.",
                            },
                            ["TL"] = {
                                "Narinig kita. Huwag mo nang ipagpilitan pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["text"] = {
                            ["EN"] = {
                                "Message received. Keep your distance.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Manatili ka sa puwesto mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Let's stay alert.",
                            },
                            ["TL"] = {
                                "Naintindihan. Maging alerto tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. No need for more words.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Hindi na kailangan ng salita.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Watching my back, you watch yours.",
                            },
                            ["TL"] = {
                                "Sige. Babantayan ko ang likod ko, bantayan mo ang sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["text"] = {
                            ["EN"] = {
                                "Noted. Keep your eyes on the road.",
                            },
                            ["TL"] = {
                                "Tala ko na. Iwan mo ang paningin mo sa daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["text"] = {
                            ["EN"] = {
                                "Heard. Leaving it at that.",
                            },
                            ["TL"] = {
                                "Narinig ko. Iiwan ko na roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["text"] = {
                            ["EN"] = {
                                "Clear enough. Let's focus on surviving.",
                            },
                            ["TL"] = {
                                "Malinaw na. Magpokus na lang tayo sa pananatiling buhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["text"] = {
                            ["EN"] = {
                                "Fair enough. Step back a bit.",
                            },
                            ["TL"] = {
                                "Makatwiran. Umatras ka nang kaunti.",
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
