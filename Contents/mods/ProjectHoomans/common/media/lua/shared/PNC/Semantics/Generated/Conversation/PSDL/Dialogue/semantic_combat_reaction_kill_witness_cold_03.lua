-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_cold",
        ["id"] = "semantic.combat.reaction.kill_witness_cold_03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_cold_03",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_cold.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_cold_03",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_cold_03",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/witness/cold.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Fine. One less.",
                            },
                            ["TL"] = {
                                "Sige. Isa na lang ang nabawas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Acceptable. Keep moving.",
                            },
                            ["TL"] = {
                                "Pwede na. Tuloy ang lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "One obstacle eliminated.",
                            },
                            ["TL"] = {
                                "Isang sagabal ang naalis.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Target down. Sufficient.",
                            },
                            ["TL"] = {
                                "Bagsak ang target. Sapat na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Threat neutralized. Proceed.",
                            },
                            ["TL"] = {
                                "Banta naalis na. Magpatuloy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "One down. March on.",
                            },
                            ["TL"] = {
                                "Isang bagsak. Magmartsa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Handled. Next sector.",
                            },
                            ["TL"] = {
                                "Naasikaso. Susunod na bahagi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Done. Do not linger.",
                            },
                            ["TL"] = {
                                "Tapos. Huwag magtagal.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Adequate strike. Keep the pace.",
                            },
                            ["TL"] = {
                                "Sapat na tama. Panatilihin ang bilis.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Casualty verified. Step forward.",
                            },
                            ["TL"] = {
                                "Kumpirmadong biktima. Hakbang pasulong.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_witness_cold.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
