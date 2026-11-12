-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_brave",
        ["id"] = "semantic.combat.reaction.kill_witness_brave_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_brave_01",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_brave.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_brave_01",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_brave_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/witness/brave.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Clean kill. Check the flanks.",
                            },
                            ["TL"] = {
                                "Malinis. Bantayan ang gilid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Good strike. Scan our blind spots.",
                            },
                            ["TL"] = {
                                "Magandang tama. Tignan ang mga bulag na sulok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Solid takedown. Watch the perimeter.",
                            },
                            ["TL"] = {
                                "Solidong pagpabagsak. Bantayan ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Downed cleanly. Keep your eyes on the sides.",
                            },
                            ["TL"] = {
                                "Bagsak nang malinis. Tumingin sa magkabilang gilid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Decisive blow. Scan the lane.",
                            },
                            ["TL"] = {
                                "Tiyak na hampas. Suriin ang daanan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Threat cleared. Watch for secondary contacts.",
                            },
                            ["TL"] = {
                                "Banta naalis. Bantayan kung may susunod pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Clean hit. Don't get tunnel vision.",
                            },
                            ["TL"] = {
                                "Malinis na tama. Huwag matutok sa iisang lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Down. Maintain field awareness.",
                            },
                            ["TL"] = {
                                "Bagsak. Maging alerto sa buong paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Well executed. Check behind cover.",
                            },
                            ["TL"] = {
                                "Magaling ang pagkagawa. Tignan sa likod ng kublihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Target neutralized. Scan all directions.",
                            },
                            ["TL"] = {
                                "Target naalis. Magmasid sa lahat ng direksyon.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_witness_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
