-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_banter_weapon_kill_reserved",
        ["id"] = "semantic.combat.kill.killer.reserved.firearm_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.kill.killer.reserved.firearm_01",
            ["sourcePath"] = "psdl/dialogue/combat_banter_weapon_kill_reserved.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_kill_killer_reserved_firearm_01",
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
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseTemplateID"] = "semantic.combat.kill.killer.reserved.firearm_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_banter/weapon_kill/reserved.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hit.",
                            },
                            ["TL"] = {
                                "Tinamaan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Down.",
                            },
                            ["TL"] = {
                                "Bagsak.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Target neutral.",
                            },
                            ["TL"] = {
                                "Target bagsak.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "One round.",
                            },
                            ["TL"] = {
                                "Isang bala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Clear.",
                            },
                            ["TL"] = {
                                "Malinis.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Eliminated.",
                            },
                            ["TL"] = {
                                "Tanggal.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Dropped.",
                            },
                            ["TL"] = {
                                "Naitumba.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Shot connected.",
                            },
                            ["TL"] = {
                                "Tumama ang putok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Neutralized.",
                            },
                            ["TL"] = {
                                "Naalis.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Done.",
                            },
                            ["TL"] = {
                                "Tapos.",
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
        ["sourceShard"] = "psdl/dialogue/combat_banter_weapon_kill_reserved.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
