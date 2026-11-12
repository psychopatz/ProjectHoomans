-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_witness_brave",
        ["id"] = "semantic.combat.reaction.kill_witness_brave_03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_witness_brave_03",
            ["sourcePath"] = "psdl/dialogue/combat_kill_witness_brave.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_witness_brave_03",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_witness_brave_03",
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
                                "Good. Keep moving before they bunch up.",
                            },
                            ["TL"] = {
                                "Ayos. Gumalaw tayo bago sila dumami.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Clean hit. Don't let them gather.",
                            },
                            ["TL"] = {
                                "Malinis na tama. Huwag silang hayaang magtipon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Downed. Advance before they form a crowd.",
                            },
                            ["TL"] = {
                                "Bagsak na. Sulong bago maging kuyog.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Handled. Push through before more arrive.",
                            },
                            ["TL"] = {
                                "Naasikaso. Lusot bago may dumating pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Threat dead. Keep moving through the area.",
                            },
                            ["TL"] = {
                                "Patay ang banta. Tuloy sa paggalaw sa lugar.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Solid kill. Advance while the lane is open.",
                            },
                            ["TL"] = {
                                "Solidong patay. Abante habang bukas ang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Target down. Move before the swarm groups.",
                            },
                            ["TL"] = {
                                "Target bagsak na. Kilos bago magsama-sama ang iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Down. Keep momentum before reinforcements come.",
                            },
                            ["TL"] = {
                                "Bagsak. Panatilihin ang bwelo bago may sumaklolo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Clean work. Don't stay stationary.",
                            },
                            ["TL"] = {
                                "Malinis na trabaho. Huwag maging nakatigil.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Handled. Keep pushing forward.",
                            },
                            ["TL"] = {
                                "Naasikaso na. Tuloy ang pagsulong.",
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
