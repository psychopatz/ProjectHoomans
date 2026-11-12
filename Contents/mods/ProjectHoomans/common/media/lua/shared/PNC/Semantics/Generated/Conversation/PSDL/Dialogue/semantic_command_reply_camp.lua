-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.command.reply.camp",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.reply.camp",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_reply_camp",
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
                ["responseTemplateID"] = "semantic.command.reply.camp",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "We'll make camp here.",
                            },
                            ["TL"] = {
                                "Magkakampo tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Setting up camp in this spot.",
                            },
                            ["TL"] = {
                                "Magtatayo ng kampo sa pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Resting here.",
                            },
                            ["TL"] = {
                                "Naintindihan. Magpapahinga rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "This place works for a camp. Securing it.",
                            },
                            ["TL"] = {
                                "Pwede ang lugar na ito para magkampo. Seselyuhan ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Making camp. Let's get comfortable.",
                            },
                            ["TL"] = {
                                "Nagtatayo ng kampo. Magpahinga na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Good spot to bed down.",
                            },
                            ["TL"] = {
                                "Magandang lugar para matulog.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Camp established. I'll settle in.",
                            },
                            ["TL"] = {
                                "Naitayo na ang kampo. Aayos na ako ng pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Dropping gear and resting.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Ibaba ang gamit at magpahinga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Setting watches and bedding down here.",
                            },
                            ["TL"] = {
                                "Magtatalaga ng bantay at matutulog dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Camp confirmed. Staying put.",
                            },
                            ["TL"] = {
                                "Kumpirmadong kampo. Mananatili rito.",
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
