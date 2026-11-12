-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "event_reactions_combat",
        ["id"] = "semantic.combat.reaction.threat",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.threat",
            ["sourcePath"] = "psdl/dialogue/event_reactions_combat.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_threat",
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
                ["responseTemplateID"] = "semantic.combat.reaction.threat",
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
                                "That threat is down. Stay alert.",
                            },
                            ["TL"] = {
                                "Bagsak na ang banta. Manatiling alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Threat neutralized. Don't drop your guard.",
                            },
                            ["TL"] = {
                                "Naalis na ang banta. Huwag ibaba ang depensa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Target eliminated. Keep watching.",
                            },
                            ["TL"] = {
                                "Target naalis na. Patuloy na magmatyag.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Danger's passed for now. Stay sharp.",
                            },
                            ["TL"] = {
                                "Lumipas na ang panganib pansamantala. Maging handa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Handled that hazard. Eyes open.",
                            },
                            ["TL"] = {
                                "Nalutas ang panganib na 'yon. Buksan ang mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Threat's in the dirt. Scan the flanks.",
                            },
                            ["TL"] = {
                                "Nasa lupa na ang banta. Suriin ang gilid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Threat ceased. Maintain alertness.",
                            },
                            ["TL"] = {
                                "Tumigil na ang banta. Panatilihin ang pag-iingat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Downed the contact. Watch your sector.",
                            },
                            ["TL"] = {
                                "Naitumba ang kalaban. Bantayan ang parte mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "No more threat from that one. Stay ready.",
                            },
                            ["TL"] = {
                                "Wala nang panganib mula sa kanya. Maging handa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Handled. Stay focused on remaining risks.",
                            },
                            ["TL"] = {
                                "Naayos na. Tutukan ang iba pang panganib.",
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
