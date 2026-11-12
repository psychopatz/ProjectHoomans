-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.return_home.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.return_home.failed",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_return_home_failed",
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
                ["responseTemplateID"] = "semantic.command.return_home.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/return_home.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't head home.",
                            },
                            ["TL"] = {
                                "Hindi ako nakauwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The path back home is completely blocked.",
                            },
                            ["TL"] = {
                                "Ganap na may harang ang daan pabalik sa tahanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to return. Too many hostiles along the route.",
                            },
                            ["TL"] = {
                                "Bigo sa pag-uwi. Masyadong maraming kalaban sa ruta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't find a safe way back to base.",
                            },
                            ["TL"] = {
                                "Wala akong makitang ligtas na daan pabalik sa base.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Return trip failed. Had to double back.",
                            },
                            ["TL"] = {
                                "Pumalpak ang pag-uwi. Kinailangang bumalik.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to reach home safely right now.",
                            },
                            ["TL"] = {
                                "Di makarating sa tahanan nang ligtas sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Tried heading back, but the streets were overrun.",
                            },
                            ["TL"] = {
                                "Sinubukang umuwi, pero pinamumugaran ang mga kalsada.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Lost the route home in the chaos.",
                            },
                            ["TL"] = {
                                "Nawala ang daan pauwi sa gitna ng gulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't reach base from this position.",
                            },
                            ["TL"] = {
                                "Di maabot ang base mula sa pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Return to base aborted. Route compromised.",
                            },
                            ["TL"] = {
                                "Itinigil ang pag-uwi sa base. May aberya sa ruta.",
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
