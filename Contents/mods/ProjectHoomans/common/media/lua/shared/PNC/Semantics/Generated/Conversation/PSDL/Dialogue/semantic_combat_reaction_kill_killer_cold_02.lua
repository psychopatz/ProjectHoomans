-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_killer_cold",
        ["id"] = "semantic.combat.reaction.kill_killer_cold_02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_killer_cold_02",
            ["sourcePath"] = "psdl/dialogue/combat_kill_killer_cold.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_killer_cold_02",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_killer_cold_02",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/killer/cold.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "It's dead. Move.",
                            },
                            ["TL"] = {
                                "Patay na. Galaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Body is neutralized. March on.",
                            },
                            ["TL"] = {
                                "Naitumba na ang katawan. Magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Ceased function. Step over.",
                            },
                            ["TL"] = {
                                "Wala nang galaw. Hakbangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Dead tissue. Proceed.",
                            },
                            ["TL"] = {
                                "Patay na laman. Tuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Target down. Do not stop.",
                            },
                            ["TL"] = {
                                "Bagsak ang target. Huwag titigil.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Eliminated. Keep walking.",
                            },
                            ["TL"] = {
                                "Naalis na. Magpatuloy sa paglalakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Threat dead. Advance.",
                            },
                            ["TL"] = {
                                "Patay ang banta. Abante.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Corpse is irrelevant. Move.",
                            },
                            ["TL"] = {
                                "Walang kwenta ang bangkay. Galaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Finished. Next position.",
                            },
                            ["TL"] = {
                                "Tapos na. Susunod na pwesto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "No heartbeat. Move on.",
                            },
                            ["TL"] = {
                                "Walang tibok ng puso. Tuloy.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_killer_cold.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
