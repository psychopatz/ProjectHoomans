-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_practical",
        ["id"] = "semantic.combat.reaction.kill_witness_practical_02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_practical_02",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_practical.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_practical_02",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_practical_02",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/witness/practical.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "One down. Watch for more.",
                            },
                            ["TL"] = {
                                "Isa na. Bantayan ang iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Good hit. Expect stragglers.",
                            },
                            ["TL"] = {
                                "Magandang tama. Asahan ang mga naiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That's one. Don't assume the area is clear.",
                            },
                            ["TL"] = {
                                "Isa 'yan. Huwag ipalagay na malinis na ang lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Downed. Listen for more footsteps.",
                            },
                            ["TL"] = {
                                "Bagsak. Makinig kung may mga yabag pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "One eliminated. Watch the windows.",
                            },
                            ["TL"] = {
                                "Isa ang tinanggal. Bantayan ang mga bintana.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Threat dead. Stay alert for secondary threats.",
                            },
                            ["TL"] = {
                                "Patay ang banta. Maging alerto sa mga susunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Handled that one. Watch the hallway.",
                            },
                            ["TL"] = {
                                "Naasikaso 'yon. Bantayan ang pasilyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "One in the dirt. Keep your guard raised.",
                            },
                            ["TL"] = {
                                "Isa sa lupa. Panatilihing nakataas ang depensa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Good takedown. More could be nearby.",
                            },
                            ["TL"] = {
                                "Magandang pagtumba. Baka may iba pang malapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Down. Keep your ears open.",
                            },
                            ["TL"] = {
                                "Bagsak. Buksan ang pandinig.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_witness_practical.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
