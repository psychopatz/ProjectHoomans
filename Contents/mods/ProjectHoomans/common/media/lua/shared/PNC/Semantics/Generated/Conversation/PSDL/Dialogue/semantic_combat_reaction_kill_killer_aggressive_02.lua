-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_killer_aggressive",
        ["id"] = "semantic.combat.reaction.kill_killer_aggressive_02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_killer_aggressive_02",
            ["sourcePath"] = "psdl/dialogue/combat_kill_killer_aggressive.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_killer_aggressive_02",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_killer_aggressive_02",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/killer/aggressive.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Down. Give me another.",
                            },
                            ["TL"] = {
                                "Patay. May kasunod pa ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Dropped. Bring them on.",
                            },
                            ["TL"] = {
                                "Bagsak. Dalhin niyo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Dead. Who's stepping up?",
                            },
                            ["TL"] = {
                                "Patay na. Sino'ng lalapit?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Finished that one. Send the next.",
                            },
                            ["TL"] = {
                                "Tinapos ko 'yon. Ipadala ang kasunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Downed. Keep feeding them to me.",
                            },
                            ["TL"] = {
                                "Bagsak. Iharap niyo lang sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Cracked open. Next in line.",
                            },
                            ["TL"] = {
                                "Basag na. Susunod sa pila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That one's done. Give me another target.",
                            },
                            ["TL"] = {
                                "Tapos na ang isang 'yon. Bigyan pa ako ng target.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Dead on the ground. Next one step forward.",
                            },
                            ["TL"] = {
                                "Patay sa lupa. Susunod lumapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Flattened. Who's next to die?",
                            },
                            ["TL"] = {
                                "Pinitpit. Sino susunod na mamamatay?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "One down. Not even winded.",
                            },
                            ["TL"] = {
                                "Isang bagsak. Hindi man lang ako hinihingal.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_killer_aggressive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
