-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.camp.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.camp.rejected",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_camp_rejected",
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
                ["responseTemplateID"] = "semantic.command.camp.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/camp.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't set up camp there right now.",
                            },
                            ["TL"] = {
                                "Hindi ako makapag-set up ng kampo roon ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "That spot is far too dangerous to sleep in.",
                            },
                            ["TL"] = {
                                "Masyadong mapanganib ang pwestong 'yon para tulugan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "No way. It's crawling with dead over there.",
                            },
                            ["TL"] = {
                                "Ayoko nga. Puno ng patay doon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I refuse to camp in that area. Find somewhere safer.",
                            },
                            ["TL"] = {
                                "Tumatanggi akong magkampo roon. Maghanap ng mas ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Too exposed. We'd get ambushed in our sleep.",
                            },
                            ["TL"] = {
                                "Masyadong bukas. Matatambangan tayo habang natutulog.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Can't camp there. No walls, no fire, no cover.",
                            },
                            ["TL"] = {
                                "Di makapagkampo roon. Walang pader, apoy, o silong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Not camping there. That's asking to be eaten alive.",
                            },
                            ["TL"] = {
                                "Di ako magkakampo roon. Parang nagpapakain tayo nang buhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to comply. That position is totally compromised.",
                            },
                            ["TL"] = {
                                "Di makasusunod. Masyadong dehado ang pwestong 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "I won't bed down there. Pick another room.",
                            },
                            ["TL"] = {
                                "Di ako hihiga roon. Pumili ka ng ibang kwarto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Camping rejected. We need real security first.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang kampo. Kailangan natin ng tunay na kaligtasan.",
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
