-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_killer_brave",
        ["id"] = "semantic.combat.reaction.kill_killer_brave_02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_killer_brave_02",
            ["sourcePath"] = "psdl/dialogue/combat_kill_killer_brave.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_killer_brave_02",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_killer_brave_02",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/killer/brave.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Watch my side.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Bantayan mo ang gilid ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Threat down. Cover my flank.",
                            },
                            ["TL"] = {
                                "Banta bagsak na. Salagin mo ang gilid ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Took that one out. Check my blind spot.",
                            },
                            ["TL"] = {
                                "Tinapos ko 'yon. Tignan ang bulag na parte ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Target eliminated. Guard the flank.",
                            },
                            ["TL"] = {
                                "Target naalis. Bantayan ang tabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Downed. Keep eyes on my right.",
                            },
                            ["TL"] = {
                                "Bagsak. Tumingin ka sa kanan ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Handled that one. Watch my shoulder.",
                            },
                            ["TL"] = {
                                "Inasikaso ko ang isang 'yon. Bantayan ang balikat ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "It's dead. Don't let anything sneak up on us.",
                            },
                            ["TL"] = {
                                "Patay na. Huwag hayaang may makapanambang sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Dead. Keep the flank tight.",
                            },
                            ["TL"] = {
                                "Patay na. Hawakan nang mahigpit ang gilid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Keep looking left and right.",
                            },
                            ["TL"] = {
                                "Nakuha ko na. Tumingin ka sa kaliwa't kanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Finished. Watch our perimeter.",
                            },
                            ["TL"] = {
                                "Tapos na. Bantayan ang buong paligid natin.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_killer_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
