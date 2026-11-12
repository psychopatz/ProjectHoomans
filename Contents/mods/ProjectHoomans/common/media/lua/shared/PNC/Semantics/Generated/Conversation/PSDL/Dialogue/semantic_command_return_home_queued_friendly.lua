-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.return_home.queued.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.return_home.queued.friendly",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_return_home_queued_friendly",
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
                ["responseTemplateID"] = "semantic.command.return_home.queued.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/return_home.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Sure, I'll head home. See you back there soon!",
                            },
                            ["TL"] = {
                                "Sige, uuwi ako. Kita tayo roon agad!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Sounds wonderful, friend. I'll get back to camp safely.",
                            },
                            ["TL"] = {
                                "Napakaganda, kaibigan. Babalik ako sa kampo nang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Heading home, partner! Make sure you stay safe too.",
                            },
                            ["TL"] = {
                                "Pauwi na, kasama! Tiyakin mong mag-iingat ka rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll go keep the fire warm for when you return.",
                            },
                            ["TL"] = {
                                "Pupunta ako para panatilihing mainit ang apoy pagbalik mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Great idea! I'll head home and stow our gear.",
                            },
                            ["TL"] = {
                                "Magandang ideya! Uuwi ako at itatabi ang gamit natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to head home. Don't stay out too late, friend!",
                            },
                            ["TL"] = {
                                "Masayang uuwi. Huwag kang magpagabi sa labas, kaibigan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "On my way back to our safe place. Take care!",
                            },
                            ["TL"] = {
                                "Papauwi na sa ligtas nating lugar. Mag-ingat ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Heading home with a smile. See you shortly, partner.",
                            },
                            ["TL"] = {
                                "Pauwi nang may ngiti. Magkita tayo maya-maya, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I'll get things tidy back at base for us.",
                            },
                            ["TL"] = {
                                "Aayusin ko ang mga gamit sa base para sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Heading home! Be careful on your way back.",
                            },
                            ["TL"] = {
                                "Pauwi na! Mag-ingat ka sa pagbalik mo.",
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
