-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.combat.horde.ack.avoid_default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.ack.avoid_default",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_ack_avoid_default",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.combat.horde.ack.avoid_default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "ACK",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Copy. We go around.",
                            },
                            ["TL"] = {
                                "Sige. Iikot tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Avoiding the swarm.",
                            },
                            ["TL"] = {
                                "Naintindihan. Iiwasan ang kawan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Bypassing the horde.",
                            },
                            ["TL"] = {
                                "Lalampasan ang kawan sa malayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Taking the side path. Quietly.",
                            },
                            ["TL"] = {
                                "Dadaan sa gilid. Nang tahimik.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Copy that. Staying out of their sight line.",
                            },
                            ["TL"] = {
                                "Kopyado. Lalayo sa paningin nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "We'll detour around them.",
                            },
                            ["TL"] = {
                                "Iikot tayo sa paligid nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. No engagement.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Walang labanang magaganap.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Steering clear of the horde.",
                            },
                            ["TL"] = {
                                "Lalayo sa kawan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Copy. Slipping past the dead.",
                            },
                            ["TL"] = {
                                "Sige. Papalusot sa mga patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Avoiding contact. Lead the way.",
                            },
                            ["TL"] = {
                                "Iiwas sa engkwentro. Ituro ang daan.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_replies.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
