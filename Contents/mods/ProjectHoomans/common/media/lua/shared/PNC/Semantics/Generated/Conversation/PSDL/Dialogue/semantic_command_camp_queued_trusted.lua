-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.camp.queued.trusted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.camp.queued.trusted",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_camp_queued_trusted",
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
                ["responseTemplateID"] = "semantic.command.camp.queued.trusted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/camp.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right, I'll make camp there.",
                            },
                            ["TL"] = {
                                "Sige, magtatayo ako ng kampo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I trust your eye for good ground. Setting up camp.",
                            },
                            ["TL"] = {
                                "Tiwala ako sa pagpili mo ng lupa. Magtatayo ng kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You picked the spot, I'll build the shelter.",
                            },
                            ["TL"] = {
                                "Pinili mo ang pwesto, itatayo ko ang silungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll make sure our campsite is locked down tight.",
                            },
                            ["TL"] = {
                                "Naintindihan. Titiyakin kong saradong-sarado ang kampo natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I know you've got our safety in mind. Making camp.",
                            },
                            ["TL"] = {
                                "Alam kong kaligtasan natin ang iniisip mo. Magkakampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Right away. We'll be secure there together.",
                            },
                            ["TL"] = {
                                "Agad-agad. Ligtas tayo roon nang magkasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'll get it ready for both of us.",
                            },
                            ["TL"] = {
                                "Ihahanda ko para sa ating dalawa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Trust your judgment completely. Camp is going up.",
                            },
                            ["TL"] = {
                                "Lubos akong nagtitiwala sa pasya mo. Itatayo na ang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Setting up camp. We earned this rest.",
                            },
                            ["TL"] = {
                                "Nagtatayo ng kampo. Karapat-dapat tayo sa pahingang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Good call, partner. I'll secure the camp perimeter.",
                            },
                            ["TL"] = {
                                "Magandang pasya, kasama. Seselyuhan ko ang paligid ng kampo.",
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
