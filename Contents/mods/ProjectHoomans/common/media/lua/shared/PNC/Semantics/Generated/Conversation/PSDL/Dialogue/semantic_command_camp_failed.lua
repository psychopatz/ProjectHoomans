-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.camp.failed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.camp.failed",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_camp_failed",
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
                ["responseTemplateID"] = "semantic.command.camp.failed",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/camp.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I couldn't set up camp there.",
                            },
                            ["TL"] = {
                                "Hindi ako nakapag-set up ng kampo roon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Failed to establish camp. That spot wasn't viable.",
                            },
                            ["TL"] = {
                                "Bigo sa pagtatayo ng kampo. Di angkop ang lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I tried to camp there, but it didn't work out.",
                            },
                            ["TL"] = {
                                "Sinubukan kong magkampo roon, pero hindi umubra.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Couldn't secure that position for a camp.",
                            },
                            ["TL"] = {
                                "Hindi ma-secure ang pwestong 'yon para sa kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Camp setup failed. The area is too exposed.",
                            },
                            ["TL"] = {
                                "Pumalpak ang pagtatayo ng kampo. Masyadong bukas ang lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to bed down there. Too many issues.",
                            },
                            ["TL"] = {
                                "Di makatulog doon. Masyadong maraming aberya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That campsite didn't pan out. Too dangerous.",
                            },
                            ["TL"] = {
                                "Di umubra ang kampong 'yon. Masyadong mapanganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Attempted to camp, but had to pull out.",
                            },
                            ["TL"] = {
                                "Sinubukang magkampo, pero kinailangang umurong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Can't pitch camp there. Ground wasn't secure.",
                            },
                            ["TL"] = {
                                "Di makapaglatag ng kampo roon. Di ligtas ang lupa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Camping attempt failed. Finding another spot.",
                            },
                            ["TL"] = {
                                "Bigo ang pagtatangkang magkampo. Maghanap ng iba.",
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
