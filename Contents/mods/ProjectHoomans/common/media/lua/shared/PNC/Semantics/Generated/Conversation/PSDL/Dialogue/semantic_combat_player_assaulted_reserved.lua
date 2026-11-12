-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_player_assault_reactions",
        ["id"] = "semantic.combat.player_assaulted.reserved",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.player_assaulted.reserved",
            ["sourcePath"] = "psdl/dialogue/combat_player_assault_reactions.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_player_assaulted_reserved",
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
                ["category"] = "projecthoomans:combat_kill",
                ["contentOwner"] = "projecthoomans.dialogue_content.combat",
                ["responseTemplateID"] = "semantic.combat.player_assaulted.reserved",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat/player_assault_reactions.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Back off. Now.",
                            },
                            ["TL"] = {
                                "Lumayo ka. Ngayon na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Enough. Stay away from me.",
                            },
                            ["TL"] = {
                                "Tama na. Lumayo ka sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Step back.",
                            },
                            ["TL"] = {
                                "Umatras ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Do not do that again.",
                            },
                            ["TL"] = {
                                "Huwag mong uulitin 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Don't touch me.",
                            },
                            ["TL"] = {
                                "Huwag mo akong hahawakan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Last warning.",
                            },
                            ["TL"] = {
                                "Huling babala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Stay back.",
                            },
                            ["TL"] = {
                                "Diyan ka lang sa malayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Drop it.",
                            },
                            ["TL"] = {
                                "Ibaba mo 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Keep your distance.",
                            },
                            ["TL"] = {
                                "Dumistansya ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "One step back. Right now.",
                            },
                            ["TL"] = {
                                "Isang hakbang pabalik. Ngayon na.",
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
        ["sourceShard"] = "psdl/dialogue/combat_player_assault_reactions.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
