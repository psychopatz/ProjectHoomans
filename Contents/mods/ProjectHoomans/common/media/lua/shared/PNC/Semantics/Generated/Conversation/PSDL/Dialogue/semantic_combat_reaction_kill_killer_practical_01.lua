-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_killer_practical",
        ["id"] = "semantic.combat.reaction.kill_killer_practical_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_killer_practical_01",
            ["sourcePath"] = "psdl/dialogue/combat_kill_killer_practical.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_killer_practical_01",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_killer_practical_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/killer/practical.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Check the area.",
                            },
                            ["TL"] = {
                                "Nakuha ko. Suriin ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Threat down. Scan before looting.",
                            },
                            ["TL"] = {
                                "Bagsak ang banta. Magmasid muna bago maghalughog.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Target neutralized. Check the perimeter.",
                            },
                            ["TL"] = {
                                "Naalis ang target. Suriin ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Downed. Clear your angles.",
                            },
                            ["TL"] = {
                                "Bagsak. Linisin ang mga anggulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Handled that one. Watch for flankers.",
                            },
                            ["TL"] = {
                                "Naasikaso ko 'yon. Bantayan ang mga nasa tabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Dead. Scan 360 degrees.",
                            },
                            ["TL"] = {
                                "Patay na. Magmasid sa buong paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Got him. Don't drop your guard.",
                            },
                            ["TL"] = {
                                "Nakuha ko na siya. Huwag ibaba ang depensa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Down. Check behind the door.",
                            },
                            ["TL"] = {
                                "Bagsak. Tignan sa likod ng pinto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Finished. Verify no more movement.",
                            },
                            ["TL"] = {
                                "Tapos na. Tiyaking wala nang gumagalaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Target down. Look around before relaxing.",
                            },
                            ["TL"] = {
                                "Bagsak ang target. Tumingin sa paligid bago magpahinga.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_killer_practical.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
