-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_practical",
        ["id"] = "semantic.combat.reaction.kill_witness_practical_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_practical_01",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_practical.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_practical_01",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_practical_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/witness/practical.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Good. Check the area.",
                            },
                            ["TL"] = {
                                "Ayos. Suriin natin ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Nice kill. Scan before moving in.",
                            },
                            ["TL"] = {
                                "Magandang patay. Magmasid bago lumapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Target down. Clear your corners.",
                            },
                            ["TL"] = {
                                "Bagsak ang target. Linisin ang mga sulok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Good takedown. Check for flankers.",
                            },
                            ["TL"] = {
                                "Magandang pagpabagsak. Tignan kung may pumapaligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Downed. Watch the shadows.",
                            },
                            ["TL"] = {
                                "Bagsak na. Bantayan ang mga anino.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Solid strike. Secure the room first.",
                            },
                            ["TL"] = {
                                "Solidong tama. Siguraduhin muna ang kwarto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Well handled. Don't step out without scanning.",
                            },
                            ["TL"] = {
                                "Maayos na napigilan. Huwag lalabas nang hindi nagmamasid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Threat cleared. Look all around.",
                            },
                            ["TL"] = {
                                "Banta naalis. Tumingin sa buong paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Clean hit. Ensure the perimeter is safe.",
                            },
                            ["TL"] = {
                                "Malinis na tama. Tiyaking ligtas ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Dropped it. Scan before continuing.",
                            },
                            ["TL"] = {
                                "Naibagsak mo. Magmasid bago magpatuloy.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_witness_practical.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
