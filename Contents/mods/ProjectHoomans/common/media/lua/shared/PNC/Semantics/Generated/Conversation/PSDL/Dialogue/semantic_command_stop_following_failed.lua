-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stop_following.failed",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[28]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_stop_following_failed",
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
                ["responseTemplateID"] = "semantic.command.stop_following.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't stop following.",
                            },
                            ["TL"] = {
                                "Hindi ako nakahinto sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to break follow stance.",
                            },
                            ["TL"] = {
                                "Bigo sa pagtigil sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I tried to hold back, but the crowd pushed me with you.",
                            },
                            ["TL"] = {
                                "Sinubukan kong huminto, pero itinulak ako ng kawan kasabay mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't disengage from following.",
                            },
                            ["TL"] = {
                                "Hindi makahiwalay sa pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Stop following failed. Route required continuous movement.",
                            },
                            ["TL"] = {
                                "Pumalpak ang paghinto sa pagsunod. Kailangan ng tuloy-tuloy na galaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to stop following right now.",
                            },
                            ["TL"] = {
                                "Di makahinto sa pagsunod ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Attempted to halt, but had to keep moving.",
                            },
                            ["TL"] = {
                                "Sinubukang huminto, pero kinailangang magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Can't detach from follow mode here.",
                            },
                            ["TL"] = {
                                "Di makahiwalay sa pagsunod dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Follow lock failed to release.",
                            },
                            ["TL"] = {
                                "Di bumitaw ang pagsunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't stop following in this tight corridor.",
                            },
                            ["TL"] = {
                                "Di makahinto sa pagsunod sa makipot na daang ito.",
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
