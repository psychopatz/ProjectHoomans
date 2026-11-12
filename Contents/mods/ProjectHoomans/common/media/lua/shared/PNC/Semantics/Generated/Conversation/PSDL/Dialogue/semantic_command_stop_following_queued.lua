-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.queued",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stop_following.queued",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[29]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_stop_following_queued",
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
                ["responseTemplateID"] = "semantic.command.stop_following.queued",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Okay, I'll stop following.",
                            },
                            ["TL"] = {
                                "Sige, titigil ako sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Breaking off pursuit.",
                            },
                            ["TL"] = {
                                "Naintindihan. Titigil na sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'll stop here and hold.",
                            },
                            ["TL"] = {
                                "Hihinto ako rito at magbabantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Ceasing follow. Standing down.",
                            },
                            ["TL"] = {
                                "Ititigil ang pagsunod. Uurong sa pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll remain in this area.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Mananatili ako sa lugar na 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right. Not following anymore.",
                            },
                            ["TL"] = {
                                "Sige. Di na susunod pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Stopping here. You go on.",
                            },
                            ["TL"] = {
                                "Hihinto rito. Mauna ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Halting my movement.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Hihinto sa paglakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Breaking off. I'll hold ground.",
                            },
                            ["TL"] = {
                                "Bumibitiw na. Hahawakan ko ang pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Stopping follow routine.",
                            },
                            ["TL"] = {
                                "Naintindihan. Ititigil ang pagsunod.",
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
