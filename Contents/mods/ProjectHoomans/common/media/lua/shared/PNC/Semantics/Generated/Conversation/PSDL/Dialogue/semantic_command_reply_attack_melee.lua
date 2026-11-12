-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.command.reply.attack_melee",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.reply.attack_melee",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_reply_attack_melee",
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
                ["responseTemplateID"] = "semantic.command.reply.attack_melee",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Going in close.",
                            },
                            ["TL"] = {
                                "Lalapit ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Melee ready. Closing the distance.",
                            },
                            ["TL"] = {
                                "Handa ang pambugbog. Lalapit na ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll take them hand-to-hand.",
                            },
                            ["TL"] = {
                                "Lalabanan ko sila nang malapitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Blade and blunt ready.",
                            },
                            ["TL"] = {
                                "Handa ang talim at pamalo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Saving ammo. Taking them up close.",
                            },
                            ["TL"] = {
                                "Magtitipid ng bala. Lalapitan ko sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Going in with melee.",
                            },
                            ["TL"] = {
                                "Lulusob nang malapitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'll crack some skulls up front.",
                            },
                            ["TL"] = {
                                "Babaliin ko ang bungo nila sa unahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Melee weapon drawn.",
                            },
                            ["TL"] = {
                                "Nakahugot na ang panlaban nang malapitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Moving into striking range.",
                            },
                            ["TL"] = {
                                "Pumupwesto na sa abot ng hampas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Close-quarters combat.",
                            },
                            ["TL"] = {
                                "Naintindihan. Malapitang bakbakan.",
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
