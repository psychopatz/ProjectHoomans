-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stay.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stay.rejected",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[27]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_stay_rejected",
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
                ["responseTemplateID"] = "semantic.command.stay.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stay.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't stay here right now.",
                            },
                            ["TL"] = {
                                "Hindi ako makapananatili rito ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Too dangerous to stay put. We need to keep moving.",
                            },
                            ["TL"] = {
                                "Masyadong mapanganib manatili rito. Kailangang gumalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I won't stay in an open kill zone.",
                            },
                            ["TL"] = {
                                "Di ako tatayo sa bukas na lugar na pugad ng patayan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Staying here is suicide. I'm coming with you.",
                            },
                            ["TL"] = {
                                "Pagpapakamatay ang manatili rito. Sasama ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I refuse to hold this spot without adequate cover.",
                            },
                            ["TL"] = {
                                "Tumatanggi akong humawak dito nang walang maayos na silong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Cannot stay here. The perimeter is totally exposed.",
                            },
                            ["TL"] = {
                                "Di makapanatili rito. Masyadong kita ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm not standing like a target. I have to move.",
                            },
                            ["TL"] = {
                                "Di ako tatayong parang target. Kailangan kong gumalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to hold position. Hostiles are too close.",
                            },
                            ["TL"] = {
                                "Di mahawakan ang pwesto. Masyadong malapit ang kalaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I won't stay behind while you need backup.",
                            },
                            ["TL"] = {
                                "Di ako maiiwan habang kailangan mo ng saklolo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Stay order rejected. We must relocate.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang pananatili. Kailangan nating lumipat.",
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
