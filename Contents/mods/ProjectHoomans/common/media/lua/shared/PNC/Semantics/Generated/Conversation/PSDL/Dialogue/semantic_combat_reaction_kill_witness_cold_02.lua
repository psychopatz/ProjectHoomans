-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_cold",
        ["id"] = "semantic.combat.reaction.kill_witness_cold_02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_cold_02",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_cold.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_cold_02",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_cold_02",
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
                                "You killed one. So what?",
                            },
                            ["TL"] = {
                                "Napatay mo ang isa. Ano ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "One corpse among millions. Step over.",
                            },
                            ["TL"] = {
                                "Isang bangkay sa milyun-milyon. Hakbangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "That was one. There are thousands more.",
                            },
                            ["TL"] = {
                                "Isa lang 'yan. May libu-libo pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Do not admire your work. Advance.",
                            },
                            ["TL"] = {
                                "Huwag mong hangaan ang gawa mo. Sulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "A rotten corpse fell. Big deal.",
                            },
                            ["TL"] = {
                                "Bumagsak ang isang bulok. Ano naman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Don't pause over it. Keep moving.",
                            },
                            ["TL"] = {
                                "Huwag kang tumigil diyan. Kilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "One less dead body standing. Next.",
                            },
                            ["TL"] = {
                                "Bawas ang isang nakatayong bangkay. Sunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "You survived a contact. Keep walking.",
                            },
                            ["TL"] = {
                                "Nakaligtas ka sa isang engkwentro. Lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "It was in the way. It fell. Move.",
                            },
                            ["TL"] = {
                                "Nakaharang, bumagsak. Kilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hardly impressive. Keep your weapon ready.",
                            },
                            ["TL"] = {
                                "Hindi nakakahanga. Ihanda ang sandata mo.",
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
