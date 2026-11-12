-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.follow.queued.repeated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.follow.queued.repeated",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_follow_queued_repeated",
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
                ["responseTemplateID"] = "semantic.command.follow.queued.repeated",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/follow.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm still following you.",
                            },
                            ["TL"] = {
                                "Sinusundan pa rin kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Already following right behind you.",
                            },
                            ["TL"] = {
                                "Nakasunod na ako mismo sa likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Still on your heels. No need to repeat.",
                            },
                            ["TL"] = {
                                "Nasa likod mo pa rin. Di na kailangang ulitin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I haven't gone anywhere. Still right here.",
                            },
                            ["TL"] = {
                                "Wala akong pinuntahan. Narito pa rin ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Following you already. Just keep walking.",
                            },
                            ["TL"] = {
                                "Sumusunod na sa 'yo. Magpatuloy ka lang sa paglalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm right behind you! Look over your shoulder.",
                            },
                            ["TL"] = {
                                "Nasa likod mo lang ako! Lumingon ka sa balikat mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Still with you. Don't worry.",
                            },
                            ["TL"] = {
                                "Kasama mo pa rin ako. Huwag kang mag-alala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Already in tow. Lead the way.",
                            },
                            ["TL"] = {
                                "Nakasunod na. Mauna ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Following you as we speak.",
                            },
                            ["TL"] = {
                                "Sumusunod sa 'yo habang nagsasalita ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already following. Keep moving.",
                            },
                            ["TL"] = {
                                "Sumusunod na ako. Tuloy lang sa paglakad.",
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
