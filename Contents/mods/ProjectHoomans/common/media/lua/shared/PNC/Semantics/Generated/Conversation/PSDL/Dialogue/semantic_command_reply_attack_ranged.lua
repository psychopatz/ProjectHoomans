-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.command.reply.attack_ranged",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.reply.attack_ranged",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_reply_attack_ranged",
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
                ["responseTemplateID"] = "semantic.command.reply.attack_ranged",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll cover you.",
                            },
                            ["TL"] = {
                                "Bibigyan kita ng takip.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Ranged weapon ready. Watching the distance.",
                            },
                            ["TL"] = {
                                "Handa ang baril. Binabantayan ang malayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Providing covering fire.",
                            },
                            ["TL"] = {
                                "Magbibigay ng suportang putok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll pick them off from here.",
                            },
                            ["TL"] = {
                                "Isa-isa ko silang titirahin mula rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Sights aligned. Firing at range.",
                            },
                            ["TL"] = {
                                "Nakatutok na ang paningin. Babaril sa malayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping my distance and shooting.",
                            },
                            ["TL"] = {
                                "Lalayo ako at magpapaputok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Overwatching with ranged fire.",
                            },
                            ["TL"] = {
                                "Naintindihan. Magbabantay gamit ang baril.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Ready on the trigger. Staying back.",
                            },
                            ["TL"] = {
                                "Nasa gatilyo ang daliri. Mananatili sa likod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Covering the field from back here.",
                            },
                            ["TL"] = {
                                "Tatakpan ko ang lugar mula rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Ranged attack stance confirmed.",
                            },
                            ["TL"] = {
                                "Kumpirmado ang malayuang pag-atake.",
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
