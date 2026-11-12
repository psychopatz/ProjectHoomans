-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "combat_kill_killer_brave",
        ["id"] = "semantic.combat.reaction.kill_killer_brave_01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.reaction.kill_killer_brave_01",
            ["sourcePath"] = "psdl/dialogue/combat_kill_killer_brave.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_reaction_kill_killer_brave_01",
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
                ["responseTemplateID"] = "semantic.combat.reaction.kill_killer_brave_01",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_kill/killer/brave.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Down. Keep moving.",
                            },
                            ["TL"] = {
                                "Patay. Tuloy tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Threat eliminated. Push forward.",
                            },
                            ["TL"] = {
                                "Banta naalis na. Sulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Target down. Don't break stride.",
                            },
                            ["TL"] = {
                                "Target bagsak na. Huwag huminto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Dead. Move through the sector.",
                            },
                            ["TL"] = {
                                "Patay na. Lusot sa bahaging 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Handled. Keep the momentum.",
                            },
                            ["TL"] = {
                                "Naasikaso. Panatilihin ang bilis.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Downed. Advance.",
                            },
                            ["TL"] = {
                                "Bagsak. Abante.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "One kill confirmed. Step up.",
                            },
                            ["TL"] = {
                                "Isang kumpirmadong patay. Sulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Clear here. Continue the push.",
                            },
                            ["TL"] = {
                                "Malinis dito. Tuloy ang pagsulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "It's down. Walk through.",
                            },
                            ["TL"] = {
                                "Bagsak na. Lakad lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Finished. Keep pace.",
                            },
                            ["TL"] = {
                                "Tapos na. Panatilihin ang hakbang.",
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
        ["sourceShard"] = "psdl/dialogue/combat_kill_killer_brave.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
