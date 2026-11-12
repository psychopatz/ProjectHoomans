-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.command.reply.stay",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.reply.stay",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[18]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_reply_stay",
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
                ["responseTemplateID"] = "semantic.command.reply.stay",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'll stay here.",
                            },
                            ["TL"] = {
                                "Mananatili ako rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Holding position right here.",
                            },
                            ["TL"] = {
                                "Hawak ko ang pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll keep watch in this spot.",
                            },
                            ["TL"] = {
                                "Magbabantay ako sa lugar na 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Standing firm.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Nakatayo rito nang matatag.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I won't budge from this area.",
                            },
                            ["TL"] = {
                                "Hindi ako aalis sa lugar na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Holding ground until you return.",
                            },
                            ["TL"] = {
                                "Bantay dito hanggang sa bumalik ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Staying put. Keep safe.",
                            },
                            ["TL"] = {
                                "Dito lang ako. Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Guarding this position.",
                            },
                            ["TL"] = {
                                "Naintindihan. Babantayan ang pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll stay right here.",
                            },
                            ["TL"] = {
                                "Dito lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Holding this spot. Don't take too long.",
                            },
                            ["TL"] = {
                                "Hawak ko ang pwesto. Huwag kang magtatagal.",
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
