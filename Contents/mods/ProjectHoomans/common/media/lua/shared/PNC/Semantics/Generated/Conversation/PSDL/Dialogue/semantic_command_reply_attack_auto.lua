-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.command.reply.attack_auto",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.reply.attack_auto",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_reply_attack_auto",
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
                ["responseTemplateID"] = "semantic.command.reply.attack_auto",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll handle it.",
                            },
                            ["TL"] = {
                                "Ako na ang bahala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Engaging as needed.",
                            },
                            ["TL"] = {
                                "Lalabanan kapag kinakailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll choose my targets.",
                            },
                            ["TL"] = {
                                "Pipiliin ko ang mga puntirya ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Free to engage. Understood.",
                            },
                            ["TL"] = {
                                "Malaya nang lumaban. Naintindihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'll fight whatever comes close.",
                            },
                            ["TL"] = {
                                "Lalabanan ko ang anumang lumapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "On it. I'll take them down as they come.",
                            },
                            ["TL"] = {
                                "Inaasikaso na. Patutumbahin ko sila habang dumarating.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Standard combat stance. Understood.",
                            },
                            ["TL"] = {
                                "Pangkaraniwang tindig sa laban. Naintindihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll defend myself and support you.",
                            },
                            ["TL"] = {
                                "Ipagtatanggol ko ang sarili at tutulungan kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Attacking at discretion.",
                            },
                            ["TL"] = {
                                "Aatake ayon sa sitwasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Engaging threats automatically.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Kusang aatake sa mga banta.",
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
