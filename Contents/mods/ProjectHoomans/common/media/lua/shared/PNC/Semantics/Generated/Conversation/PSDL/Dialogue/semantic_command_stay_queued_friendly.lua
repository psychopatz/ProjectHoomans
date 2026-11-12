-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stay.queued.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stay.queued.friendly",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[23]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_stay_queued_friendly",
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
                ["responseTemplateID"] = "semantic.command.stay.queued.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stay.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Sure, I'll stay here. Take your time, friend!",
                            },
                            ["TL"] = {
                                "Sige, mananatili ako rito. Huwag kang magmadali, kaibigan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'll keep watch right here, partner. Be careful!",
                            },
                            ["TL"] = {
                                "Magbabantay ako rito, kasama. Mag-ingat ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "No problem! I'll guard our spot until you get back.",
                            },
                            ["TL"] = {
                                "Walang problema! Babantayan ko ang pwesto natin hanggang makabalik ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to hold the fort here for you, friend.",
                            },
                            ["TL"] = {
                                "Masayang babantayan ang kuta rito para sa 'yo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Sure thing! I'll be waiting right here for you.",
                            },
                            ["TL"] = {
                                "Walang anuman! Maghihintay ako rito mismo para sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I won't wander off. Stay safe out there, partner!",
                            },
                            ["TL"] = {
                                "Di ako lalayo. Mag-ingat ka sa labas, kasama!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Holding the line right here with a smile. Go do what you need to do.",
                            },
                            ["TL"] = {
                                "Hawak ang linya rito nang may ngiti. Gawin mo ang kailangan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll make sure nobody sneaks past this spot, friend.",
                            },
                            ["TL"] = {
                                "Titiyakin kong walang makalulusot dito, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Resting my feet and keeping watch. See you soon!",
                            },
                            ["TL"] = {
                                "Ipapahinga ang paa at magbabantay. Kita tayo agad!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "All good! I'll be right here when you return.",
                            },
                            ["TL"] = {
                                "Ayos ang lahat! Narito lang ako pagbalik mo.",
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
