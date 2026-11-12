-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.return_home.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.return_home.rejected",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_return_home_rejected",
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
                ["responseTemplateID"] = "semantic.command.return_home.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/return_home.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't head home right now.",
                            },
                            ["TL"] = {
                                "Hindi ako makauuwi ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "The road home is cut off by hordes.",
                            },
                            ["TL"] = {
                                "Pinutol ng mga kawan ang daan pauwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not leaving you out here alone. Can't go home.",
                            },
                            ["TL"] = {
                                "Di kita iiwan dito nang mag-isa. Di ako uuwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Too much danger on the way back right now.",
                            },
                            ["TL"] = {
                                "Masyadong maraming panganib sa daan pabalik ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Refusing to return home while we're surrounded.",
                            },
                            ["TL"] = {
                                "Tumatangging umuwi habang napapaligiran tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I have to finish what we started before I head back.",
                            },
                            ["TL"] = {
                                "Kailangan kong tapusin ang sinimulan bago umuwi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Can't head home. The gates are compromised.",
                            },
                            ["TL"] = {
                                "Di makauwi. May sira ang tarangkahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to return to base right now.",
                            },
                            ["TL"] = {
                                "Di makabalik sa base sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I won't abandon the mission to go home now.",
                            },
                            ["TL"] = {
                                "Di ko tatalikuran ang misyon para lang umuwi ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Return home rejected. Not safe to travel.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang pag-uwi. Di ligtas maglakbay.",
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
