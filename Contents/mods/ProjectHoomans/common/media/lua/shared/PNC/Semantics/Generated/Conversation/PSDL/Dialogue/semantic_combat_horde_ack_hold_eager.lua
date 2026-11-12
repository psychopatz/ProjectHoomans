-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.combat.horde.ack.hold_eager",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.ack.hold_eager",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_ack_hold_eager",
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
                ["responseTemplateID"] = "semantic.combat.horde.ack.hold_eager",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "ACK",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Holding. Say when.",
                            },
                            ["TL"] = {
                                "Hawak muna. Sabihin mo kung kailan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Ready on your mark! Holding position.",
                            },
                            ["TL"] = {
                                "Handa sa hudyat mo! Hawak ang pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Coiled like a spring. Just give the word.",
                            },
                            ["TL"] = {
                                "Nakahandang sumugod. Sabihin mo lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Holding fire, but twitching to go.",
                            },
                            ["TL"] = {
                                "Tigil-putok, pero sabik nang sumugod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Ready to pounce. Standing by.",
                            },
                            ["TL"] = {
                                "Handang lumundag. Naghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm locked on! Say the word and I strike.",
                            },
                            ["TL"] = {
                                "Nakatutok na! Sabihin mo lang at aatake ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Holding here. Don't make me wait too long!",
                            },
                            ["TL"] = {
                                "Dito muna. Huwag mo akong paghintayin nang matagal!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Ready and waiting! Give the signal.",
                            },
                            ["TL"] = {
                                "Handa at naghihintay! Ibigay ang senyas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Poised to attack. Holding ground.",
                            },
                            ["TL"] = {
                                "Handang sumugod. Hawak ang lupa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Just say the word. I'm ready.",
                            },
                            ["TL"] = {
                                "Sabihin mo lang. Handa na ako.",
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
