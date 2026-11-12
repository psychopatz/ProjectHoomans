-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_combat",
        ["id"] = "semantic.combat.reaction.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.default",
            ["sourcePath"] = "psdl/dialogue/event_reactions_combat.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_default",
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
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseTemplateID"] = "semantic.combat.reaction.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/reactions/combat.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Good work. Keep watching the area.",
                            },
                            ["TL"] = {
                                "Magandang trabaho. Patuloy na bantayan ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Threat's handled. Stay on your toes.",
                            },
                            ["TL"] = {
                                "Naasikaso ang banta. Maging handa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Nice job. Don't relax just yet.",
                            },
                            ["TL"] = {
                                "Mahusay. Huwag munang magpakampante.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Target down. Keep scanning the perimeter.",
                            },
                            ["TL"] = {
                                "Bagsak ang target. Patuloy na suriin ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Handled. Watch your surroundings.",
                            },
                            ["TL"] = {
                                "Naasikaso na. Bantayan ang paligid mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Good strike. Stay vigilant.",
                            },
                            ["TL"] = {
                                "Magandang tama. Manatiling alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That one's finished. Check the corners.",
                            },
                            ["TL"] = {
                                "Tapos na ang isang 'yon. Tignan ang mga sulok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Well done. Keep weapons at the ready.",
                            },
                            ["TL"] = {
                                "Magaling. Ihanda pa rin ang sandata.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Clear here. Eyes on the shadows.",
                            },
                            ["TL"] = {
                                "Malinis dito. Tumingin sa mga anino.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Threat eliminated. Keep moving carefully.",
                            },
                            ["TL"] = {
                                "Banta naalis na. Tuloy sa maingat na pagkilos.",
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
        ["sourceShard"] = "psdl/dialogue/event_reactions_combat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
