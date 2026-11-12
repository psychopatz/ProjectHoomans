-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_killer_shaken",
        ["id"] = "semantic.combat.reaction.kill_killer_shaken_02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_killer_shaken_02",
            ["sourcePath"] = "psdl/dialogue/combat_kill_killer_shaken.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_killer_shaken_02",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_killer_shaken_02",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/killer/shaken.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. I need a breath.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Kailangan ko munang huminga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "It's dead. Let me catch my breath.",
                            },
                            ["TL"] = {
                                "Patay na. Pahingahin mo muna ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Down. I can barely breathe right now.",
                            },
                            ["TL"] = {
                                "Bagsak. Halos hindi ako makahinga ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Took it out... need air.",
                            },
                            ["TL"] = {
                                "Tinapos ko na... kailangan ko ng hangin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Dead. Just let me inhale for a second.",
                            },
                            ["TL"] = {
                                "Patay na. Hayaan mo muna akong huminga nang malalim.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I got it down. Deep breath... deep breath.",
                            },
                            ["TL"] = {
                                "Naibagsak ko na. Malalim na hininga... malalim na hininga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Finished. My lungs are burning.",
                            },
                            ["TL"] = {
                                "Tapos na. Parang nasusunog ang baga ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "It's on the ground. Catching my breath.",
                            },
                            ["TL"] = {
                                "Nasa lupa na. Humihinga muna ako nang maayos.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Just need ten seconds to breathe.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Kailangan ko lang ng sampung segundo para huminga.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Killed it. Breathing hard... one second.",
                            },
                            ["TL"] = {
                                "Napatay ko na. Hinihingal ako... isang saglit.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_killer_shaken.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
