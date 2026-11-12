-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_banter_weapon_kill_supportive",
        ["id"] = "semantic.combat.kill.killer.supportive.firearm_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.kill.killer.supportive.firearm_01",
            ["sourcePath"] = "psdl/dialogue/combat_banter_weapon_kill_supportive.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_kill_killer_supportive_firearm_01",
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
                ["responseTemplateID"] = "semantic.combat.kill.killer.supportive.firearm_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_banter/weapon_kill/supportive.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. You good?",
                            },
                            ["TL"] = {
                                "Nakuha ko. Ayos ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Threat's down. Check yourself.",
                            },
                            ["TL"] = {
                                "Bagsak ang banta. Tignan mo sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Downed that one. I've got your back.",
                            },
                            ["TL"] = {
                                "Ibinagsak ko ang isa. Hawak ko ang likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Clear! You hurt anywhere?",
                            },
                            ["TL"] = {
                                "Malinis! May tama ka ba kahit saan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Got him off us. Stay close.",
                            },
                            ["TL"] = {
                                "Nailayo ko sa atin. Dumikit ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Dropped that one. Keep your eyes open.",
                            },
                            ["TL"] = {
                                "Bagsak na 'yon. Manatiling gising ang mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Took care of it. Are you alright?",
                            },
                            ["TL"] = {
                                "Inasikaso ko na. Ayos ka lang?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Shot landed. You safe?",
                            },
                            ["TL"] = {
                                "Tumama ang putok. Ligtas ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Target down. Covering you.",
                            },
                            ["TL"] = {
                                "Bagsak ang target. Sinasalag kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "That one's finished. Watch the flanks.",
                            },
                            ["TL"] = {
                                "Tapos na ang isang 'yon. Bantayan ang gilid.",
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
        ["sourceShard"] = "psdl/dialogue/combat_banter_weapon_kill_supportive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
