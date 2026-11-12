-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["id"] = "semantic.combat.horde.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.default",
            ["sourcePath"] = "psdl/dialogue/companion_commands_combat.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_default",
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
                ["responseTemplateID"] = "semantic.combat.horde.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_horde_reactions.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Horde nearby. Keep your eyes up.",
                            },
                            ["TL"] = {
                                "May kuyog na malapit. Magmatyag tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Large group in the vicinity. Tread quietly.",
                            },
                            ["TL"] = {
                                "Malaking grupo sa paligid. Huwag gumawa ng ingay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "There's a swarm around here. Stay cautious.",
                            },
                            ["TL"] = {
                                "May kuyog sa lugar na 'to. Mag-ingat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I hear heavy movement outside. Watch yourself.",
                            },
                            ["TL"] = {
                                "May naririnig akong maraming yabag sa labas. Mag-ingat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Pack of infected close by. Stay alert.",
                            },
                            ["TL"] = {
                                "Grupo ng infected malapit dito. Maging alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "We're near a wandering horde. Keep low.",
                            },
                            ["TL"] = {
                                "Malapit tayo sa palakad-lakad na kuyog. Yumuko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Too much shuffling out there. Keep weapons ready.",
                            },
                            ["TL"] = {
                                "Masyadong maraming kaluskos sa labas. Ihanda ang sandata.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Dead are gathering nearby. Stay on your toes.",
                            },
                            ["TL"] = {
                                "Nagtitipon ang mga patay malapit dito. Maging handa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Horde in the area. Pick your steps carefully.",
                            },
                            ["TL"] = {
                                "May kuyog sa paligid. Piliin nang maigi ang bawat hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Infected swarm close. Don't make unnecessary noise.",
                            },
                            ["TL"] = {
                                "Malapit ang kuyog ng infected. Huwag gumawa ng ingay.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_combat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
