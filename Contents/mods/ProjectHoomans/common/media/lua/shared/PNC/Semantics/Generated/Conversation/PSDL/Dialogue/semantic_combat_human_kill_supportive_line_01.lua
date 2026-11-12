-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_human_banter_human_kill_supportive",
        ["id"] = "semantic.combat.human_kill.supportive.line_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.human_kill.supportive.line_01",
            ["sourcePath"] = "psdl/dialogue/combat_human_banter_human_kill_supportive.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_human_kill_supportive_line_01",
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
                ["contentOwner"] = "projecthoomans.dialogue_content.combat_human",
                ["responseTemplateID"] = "semantic.combat.human_kill.supportive.line_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_human_banter/human_kill/supportive.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "He's down. You alright?",
                            },
                            ["TL"] = {
                                "Bagsak na siya. Ayos ka?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Got the shooter. Did you take any hits?",
                            },
                            ["TL"] = {
                                "Naitumba ang bumaril. Tinamaan ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "He's dead. Are you hurt anywhere?",
                            },
                            ["TL"] = {
                                "Patay na siya. May masakit ba sa'yo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Took him down. Check yourself over.",
                            },
                            ["TL"] = {
                                "Ibinagsak ko na. Tignan mo ang katawan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Threat is eliminated. You safe?",
                            },
                            ["TL"] = {
                                "Wala na ang banta. Ligtas ka ba?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I got him off you. Breathe.",
                            },
                            ["TL"] = {
                                "Nailayo ko sa'yo. Huminga ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "He's not getting back up. You good?",
                            },
                            ["TL"] = {
                                "Hindi na siya babangon. Ayos ka lang?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Downed the gunman. Stay with me.",
                            },
                            ["TL"] = {
                                "Bagsak ang may baril. Sumabay ka sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "It's okay, I got him. Check your wounds.",
                            },
                            ["TL"] = {
                                "Ayos lang, nakuha ko na siya. Tignan ang mga sugat mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Shooter's dead. We're still standing.",
                            },
                            ["TL"] = {
                                "Patay na ang bumaril. Nakatayo pa rin tayo.",
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
        ["sourceShard"] = "psdl/dialogue/combat_human_banter_human_kill_supportive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
