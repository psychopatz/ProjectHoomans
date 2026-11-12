-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_human_banter_human_kill_supportive",
        ["id"] = "semantic.combat.human_kill.supportive.line_03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.human_kill.supportive.line_03",
            ["sourcePath"] = "psdl/dialogue/combat_human_banter_human_kill_supportive.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_human_kill_supportive_line_03",
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
                ["responseTemplateID"] = "semantic.combat.human_kill.supportive.line_03",
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
                                "He's dead. Check yourself for hits.",
                            },
                            ["TL"] = {
                                "Patay na siya. Tingnan mo kung tinamaan ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Threat cleared. Inspect your gear and clothes.",
                            },
                            ["TL"] = {
                                "Malinis ang banta. Tignan ang gamit at damit mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "He's gone. Any blood on you?",
                            },
                            ["TL"] = {
                                "Wala na siya. May dugo ba sa'yo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Got him down. Tell me if you're bleeding.",
                            },
                            ["TL"] = {
                                "Ibinagsak ko na. Sabihin mo agad kung dumurugo ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Shooter is dead. Check each other over.",
                            },
                            ["TL"] = {
                                "Patay na ang bumaril. Magtinginan tayo kung may tama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Target down. Do a quick self-check.",
                            },
                            ["TL"] = {
                                "Bagsak ang target. Mag-check ka agad sa sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "He's finished. Make sure you weren't grazed.",
                            },
                            ["TL"] = {
                                "Tapos na siya. Siguraduhing hindi ka nadaplisan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Downed. Patch up if you need to.",
                            },
                            ["TL"] = {
                                "Bagsak. Magbenda ka kung kailangan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Confirmed kill. Are all your limbs okay?",
                            },
                            ["TL"] = {
                                "Kumpirmadong patay. Ayos ba lahat ng braso at binti mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "He's on the ground. Check your condition.",
                            },
                            ["TL"] = {
                                "Nasa lupa na siya. Tignan ang kondisyon mo.",
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
