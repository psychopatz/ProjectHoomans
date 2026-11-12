-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_human_banter_human_kill_reserved",
        ["id"] = "semantic.combat.human_kill.reserved.line_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.human_kill.reserved.line_01",
            ["sourcePath"] = "psdl/dialogue/combat_human_banter_human_kill_reserved.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_human_kill_reserved_line_01",
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
                ["responseTemplateID"] = "semantic.combat.human_kill.reserved.line_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/combat_human_banter/human_kill/reserved.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "He's down.",
                            },
                            ["TL"] = {
                                "Bagsak na siya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hostile down.",
                            },
                            ["TL"] = {
                                "Kalaban bagsak.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Shooter eliminated.",
                            },
                            ["TL"] = {
                                "Bumaril naalis.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Dead.",
                            },
                            ["TL"] = {
                                "Patay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Threat removed.",
                            },
                            ["TL"] = {
                                "Banta naalis.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Finished.",
                            },
                            ["TL"] = {
                                "Tapos na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Downed.",
                            },
                            ["TL"] = {
                                "Naitumba.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "No more fire from him.",
                            },
                            ["TL"] = {
                                "Wala nang putok mula sa kanya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Target down.",
                            },
                            ["TL"] = {
                                "Target bagsak.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Ceased.",
                            },
                            ["TL"] = {
                                "Tumigil.",
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
        ["sourceShard"] = "psdl/dialogue/combat_human_banter_human_kill_reserved.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
