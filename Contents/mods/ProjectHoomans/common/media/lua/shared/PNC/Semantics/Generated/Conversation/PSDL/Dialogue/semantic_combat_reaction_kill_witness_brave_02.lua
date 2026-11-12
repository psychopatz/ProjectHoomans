-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_brave",
        ["id"] = "semantic.combat.reaction.kill_witness_brave_02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_brave_02",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_brave.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_brave_02",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_brave_02",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/witness/brave.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "One down. Keep your head up.",
                            },
                            ["TL"] = {
                                "Isa na. Huwag magpakampante.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Good kill. Stay vigilant.",
                            },
                            ["TL"] = {
                                "Magandang patay. Manatiling gising.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Threat eliminated. Maintain discipline.",
                            },
                            ["TL"] = {
                                "Banta naalis. Panatilihin ang disiplina.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "That's one less. Eyes open.",
                            },
                            ["TL"] = {
                                "Bawas ang isa. Buksan ang mga mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Downed. Don't relax your posture.",
                            },
                            ["TL"] = {
                                "Bagsak na. Huwag magpakarelax sa tindig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Handled. Keep looking forward.",
                            },
                            ["TL"] = {
                                "Naasikaso. Patuloy na tumingin sa unahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "One in the dirt. Stay sharp.",
                            },
                            ["TL"] = {
                                "Isa sa lupa. Maging matalas ang pakiramdam.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Solid work. Keep ready for the next.",
                            },
                            ["TL"] = {
                                "Solido. Maging handa sa susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Target down. Don't lose focus.",
                            },
                            ["TL"] = {
                                "Target bagsak na. Huwag mawalan ng pokus.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Good takedown. Hold your stance.",
                            },
                            ["TL"] = {
                                "Magandang pagtumba. Hawakan ang pwesto mo.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_witness_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
