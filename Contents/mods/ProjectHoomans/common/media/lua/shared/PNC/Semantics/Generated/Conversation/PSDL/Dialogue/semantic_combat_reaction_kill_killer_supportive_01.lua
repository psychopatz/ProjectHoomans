-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_killer_supportive",
        ["id"] = "semantic.combat.reaction.kill_killer_supportive_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_killer_supportive_01",
            ["sourcePath"] = "psdl/dialogue/combat_kill_killer_supportive.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_killer_supportive_01",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_killer_supportive_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/killer/supportive.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Got it. Stay close.",
                            },
                            ["TL"] = {
                                "Patay na. Dito ka lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Threat down. Stay right by me.",
                            },
                            ["TL"] = {
                                "Bagsak ang banta. Dito ka lang sa tabi ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I took care of it. Keep tight.",
                            },
                            ["TL"] = {
                                "Inasikaso ko na. Dumikit ka lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got that one. Don't drift away.",
                            },
                            ["TL"] = {
                                "Nakuha ko na 'yon. Huwag kang lumayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "It's dead. I've got this side covered.",
                            },
                            ["TL"] = {
                                "Patay na. Hawak ko ang parteng 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Downed it. Stick with me.",
                            },
                            ["TL"] = {
                                "Ibinagsak ko na. Sumama ka sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That one's finished. Keep close to my shoulder.",
                            },
                            ["TL"] = {
                                "Tapos na ang isang 'yon. Dumikit sa balikat ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Handled. Watch the rear while I lead.",
                            },
                            ["TL"] = {
                                "Naasikaso na. Bantayan ang likod habang nangunguna ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Target down. Stay near.",
                            },
                            ["TL"] = {
                                "Bagsak ang target. Diyan ka lang sa malapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Took it out. We're safe on this side.",
                            },
                            ["TL"] = {
                                "Tinapos ko na. Ligtas tayo sa parteng 'to.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_killer_supportive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
