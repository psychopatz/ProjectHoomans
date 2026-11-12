-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.command.reply.attack_none",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.reply.attack_none",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_reply_attack_none",
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
                ["responseTemplateID"] = "semantic.command.reply.attack_none",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll avoid trouble.",
                            },
                            ["TL"] = {
                                "Iiwas ako sa gulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Holding fire. Keeping passive.",
                            },
                            ["TL"] = {
                                "Tigil-putok. Mananatiling tahimik.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Staying out of fights.",
                            },
                            ["TL"] = {
                                "Lalayo ako sa anumang labanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Ceasing all attacks.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Ititigil ang lahat ng atake.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I won't provoke anything.",
                            },
                            ["TL"] = {
                                "Wala akong gagalawin o pupukawin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping my weapon stowed.",
                            },
                            ["TL"] = {
                                "Nakatago ang armas ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Pacifist stance. Understood.",
                            },
                            ["TL"] = {
                                "Tahimik na paninindigan. Naintindihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll steer clear of hostiles.",
                            },
                            ["TL"] = {
                                "Iiwas ako sa mga kalaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Standing down from combat.",
                            },
                            ["TL"] = {
                                "Uuurong sa laban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "No attacking. Got it.",
                            },
                            ["TL"] = {
                                "Walang aatake. Nakuha ko.",
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
