-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_supportive",
        ["id"] = "semantic.combat.reaction.kill_witness_supportive_03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_supportive_03",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_supportive.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_supportive_03",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_supportive_03",
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
                                "You got it. I'm with you.",
                            },
                            ["TL"] = {
                                "Napatumba mo. Kasama mo ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Good takedown. I've got your back.",
                            },
                            ["TL"] = {
                                "Magandang pagtumba. Hawak ko ang likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "You dropped that threat. I'm right behind you.",
                            },
                            ["TL"] = {
                                "Naibagsak mo ang banta. Nasa likod mo lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Nice work! You can count on me.",
                            },
                            ["TL"] = {
                                "Magaling! Makakaasa ka sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "You finished it. I'm watching our rear.",
                            },
                            ["TL"] = {
                                "Tinapos mo na. Binabantayan ko ang likod natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Solid kill. We make a good team.",
                            },
                            ["TL"] = {
                                "Solidong patay. Maganda tayong magkasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "You took him down. We're in this together.",
                            },
                            ["TL"] = {
                                "Ibinagsak mo siya. Magkasama tayo rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Handled cleanly. I'll cover your flank.",
                            },
                            ["TL"] = {
                                "Malinis na naasikaso. Sasalagin ko ang gilid mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Good strike. I've got you covered.",
                            },
                            ["TL"] = {
                                "Magandang tama. Nakabantay ako sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "You got that one. I'm right here.",
                            },
                            ["TL"] = {
                                "Nakuha mo 'yon. Nandito lang ako.",
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
