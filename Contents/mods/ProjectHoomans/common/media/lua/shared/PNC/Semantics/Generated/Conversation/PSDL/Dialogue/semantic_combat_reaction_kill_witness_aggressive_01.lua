-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_aggressive",
        ["id"] = "semantic.combat.reaction.kill_witness_aggressive_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_aggressive_01",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_aggressive.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_aggressive_01",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_aggressive_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/witness/aggressive.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Nice. Hit the next one.",
                            },
                            ["TL"] = {
                                "Ayos. Sunod naman.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Good strike! Take down another.",
                            },
                            ["TL"] = {
                                "Magandang tama! Magpabagsak pa ng isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Solid hit! Keep swinging.",
                            },
                            ["TL"] = {
                                "Solidong palo! Tuloy ang hataw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Dropped 'em! Who's next in line?",
                            },
                            ["TL"] = {
                                "Ibinagsak mo! Sino'ng susunod sa pila?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Beautiful kill! Take the next one out.",
                            },
                            ["TL"] = {
                                "Gandang patay! Itumba ang kasunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "That skull shattered! Don't stop now.",
                            },
                            ["TL"] = {
                                "Basag ang bungo! Huwag kang titigil ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Down it goes! Next target is yours.",
                            },
                            ["TL"] = {
                                "Bagsak na! Sa'yo ang susunod na target.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Great shot! Press the attack.",
                            },
                            ["TL"] = {
                                "Galing ng tira! Tuloy ang pagsugod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Tore right through it! Keep going.",
                            },
                            ["TL"] = {
                                "Tumagos agad! Tuloy lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hard hit! Line up the next one.",
                            },
                            ["TL"] = {
                                "Malakas na tama! Ihanda ang kasunod.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_witness_aggressive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
