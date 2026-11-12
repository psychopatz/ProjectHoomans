-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_supportive",
        ["id"] = "semantic.combat.reaction.kill_witness_supportive_02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_supportive_02",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_supportive.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_supportive_02",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_supportive_02",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/witness/supportive.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Nice hit. Stay close to me.",
                            },
                            ["TL"] = {
                                "Maganda 'yon. Dito ka lang malapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Great strike. Don't wander away.",
                            },
                            ["TL"] = {
                                "Magandang hampas. Huwag kang lalayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Good kill. Stick close to my side.",
                            },
                            ["TL"] = {
                                "Magandang patay. Dumikit ka sa tabi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "You took care of it. Stay near.",
                            },
                            ["TL"] = {
                                "Inasikaso mo na. Manatili sa malapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Well handled. Keep on my shoulder.",
                            },
                            ["TL"] = {
                                "Maayos na napigilan. Manatili sa balikat ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Solid hit. Let's stay together.",
                            },
                            ["TL"] = {
                                "Solidong tama. Magsama tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "You dropped it. Tighten the formation.",
                            },
                            ["TL"] = {
                                "Naibagsak mo. Higpitan ang hanay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Nice swing. Keep within reach.",
                            },
                            ["TL"] = {
                                "Magandang hataw. Manatili sa abot-kamay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Downed. Don't step too far ahead.",
                            },
                            ["TL"] = {
                                "Bagsak. Huwag lalayo nang sobra sa unahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Good work. Stick by me while we clear.",
                            },
                            ["TL"] = {
                                "Magandang trabaho. Dumikit sa akin habang naglilinis.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_witness_supportive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
