-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stay.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stay.failed",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[21]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_stay_failed",
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
                ["responseTemplateID"] = "semantic.command.stay.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stay.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't start the stay order.",
                            },
                            ["TL"] = {
                                "Hindi ko masimulan ang utos na manatili.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to hold position here.",
                            },
                            ["TL"] = {
                                "Bigo sa paghawak ng pwesto rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I tried to stay, but the ground wasn't safe.",
                            },
                            ["TL"] = {
                                "Sinubukan kong manatili, pero di ligtas ang lupa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't lock down this position.",
                            },
                            ["TL"] = {
                                "Di maikandado ang pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Stay command failed. Enemies forced me to move.",
                            },
                            ["TL"] = {
                                "Pumalpak ang pananatili. Pinilit akong gumalaw ng kalaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to stay put in this area.",
                            },
                            ["TL"] = {
                                "Di makapanatili sa lugar na ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Holding ground failed. Too much incoming fire.",
                            },
                            ["TL"] = {
                                "Bigo ang paghawak sa pwesto. Masyadong maraming putok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Can't stay here. Position is untenable.",
                            },
                            ["TL"] = {
                                "Di makapanatili rito. Masyadong dehado ang pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Attempted to hold, but got pushed back.",
                            },
                            ["TL"] = {
                                "Sinubukang humawak, pero naitulak paatras.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Could not secure a stay order here.",
                            },
                            ["TL"] = {
                                "Hindi ma-secure ang pananatili rito.",
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
