-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.follow.queued.trusted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.follow.queued.trusted",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_follow_queued_trusted",
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
                ["responseTemplateID"] = "semantic.command.follow.queued.trusted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/follow.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I know you. I'll follow.",
                            },
                            ["TL"] = {
                                "Kilala kita. Susunod ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I trust your lead completely. Following you.",
                            },
                            ["TL"] = {
                                "Lubos akong nagtitiwala sa pangunguna mo. Susunod sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Lead the way, partner. I'm with you to the end.",
                            },
                            ["TL"] = {
                                "Ituro ang daan, kasama. Kasama mo ako hanggang dulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "You've proven your judgment. I'll follow anywhere.",
                            },
                            ["TL"] = {
                                "Napatunayan mo na ang galing mo. Susunod ako kahit saan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I trust you to keep us alive.",
                            },
                            ["TL"] = {
                                "Naintindihan. Tiwala akong bubuhayin mo tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right behind you. We watch out for one another.",
                            },
                            ["TL"] = {
                                "Nasa likod mo lang. Nagbabantayan tayo sa isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm at your side, friend. Lead on.",
                            },
                            ["TL"] = {
                                "Nasa tabi mo ako, kaibigan. Mauna ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "You make the calls, I back you up. Following.",
                            },
                            ["TL"] = {
                                "Ikaw ang magpasya, susuportahan kita. Sumusunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I know you have my back. Following your lead.",
                            },
                            ["TL"] = {
                                "Alam kong hawak mo ang likod ko. Sumusunod sa pangunguna mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood, partner. Right behind you.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko, kasama. Nasa likod mo lang.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
