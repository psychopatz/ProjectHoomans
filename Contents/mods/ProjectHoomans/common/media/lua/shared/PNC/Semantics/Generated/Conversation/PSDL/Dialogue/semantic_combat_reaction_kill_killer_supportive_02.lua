-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_killer_supportive",
        ["id"] = "semantic.combat.reaction.kill_killer_supportive_02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_killer_supportive_02",
            ["sourcePath"] = "psdl/dialogue/combat_kill_killer_supportive.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_killer_supportive_02",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_killer_supportive_02",
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
                                "It's down. You alright?",
                            },
                            ["TL"] = {
                                "Tapos na. Okay ka lang?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Got it off us. Are you hurt?",
                            },
                            ["TL"] = {
                                "Nailayo ko sa atin. Nasaktan ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Threat eliminated. You doing okay?",
                            },
                            ["TL"] = {
                                "Naalis ang banta. Ayos ka lang ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "It's dead. Check yourself over.",
                            },
                            ["TL"] = {
                                "Patay na. Tignan mo sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Downed that one. Everything alright with you?",
                            },
                            ["TL"] = {
                                "Ibinagsak ko 'yon. Ayos lang ang lahat sa'yo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Took it down. You safe there?",
                            },
                            ["TL"] = {
                                "Ibinagsak ko na. Ligtas ka riyan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "That one's done for. Are you okay?",
                            },
                            ["TL"] = {
                                "Tapos na 'yon. Ayos ka lang?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Dropped it before it reached you. You good?",
                            },
                            ["TL"] = {
                                "Ibinagsak bago pa makalapit sa'yo. Ayos ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Handled that threat. How are you holding up?",
                            },
                            ["TL"] = {
                                "Naasikaso ang banta. Kamusta ka riyan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "It won't touch you now. You alright?",
                            },
                            ["TL"] = {
                                "Hindi ka na mahahawakan no'n. Okay ka lang?",
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
