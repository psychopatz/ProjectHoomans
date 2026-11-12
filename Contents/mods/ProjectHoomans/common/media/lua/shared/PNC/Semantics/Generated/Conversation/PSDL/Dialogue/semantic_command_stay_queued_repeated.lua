-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stay.queued.repeated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stay.queued.repeated",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[24]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_stay_queued_repeated",
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
                ["responseTemplateID"] = "semantic.command.stay.queued.repeated",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stay.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already staying here.",
                            },
                            ["TL"] = {
                                "Nananatili na ako rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Still holding this spot. Haven't budged.",
                            },
                            ["TL"] = {
                                "Hawak pa rin ang pwesto. Di gumagalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm already staying put, don't worry.",
                            },
                            ["TL"] = {
                                "Dito na nga ako, huwag kang mag-alala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Haven't moved an inch. Still right here.",
                            },
                            ["TL"] = {
                                "Di gumalaw kahit isang pulgada. Narito pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Still guarding this exact position.",
                            },
                            ["TL"] = {
                                "Binabantayan pa rin ang mismong posisyong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I heard you before. I'm staying right here.",
                            },
                            ["TL"] = {
                                "Narinig na kita kanina. Dito lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Already holding ground. Go on.",
                            },
                            ["TL"] = {
                                "Hawak na ang lupa. Sige na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Still staying here. No need to remind me.",
                            },
                            ["TL"] = {
                                "Nananatili pa rin dito. Di na kailangang ipaalala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'm rooted right here. Keep moving.",
                            },
                            ["TL"] = {
                                "Nakatuntong na ako rito. Tuloy ka na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Already staying. I'm watching the area.",
                            },
                            ["TL"] = {
                                "Nandito na nga. Binabantayan ko ang lugar.",
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
