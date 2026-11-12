-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["id"] = "semantic.combat.horde.prompt.reserved",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.prompt.reserved",
            ["sourcePath"] = "psdl/dialogue/companion_commands_combat.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_prompt_reserved",
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
                ["category"] = "projecthoomans:companion_commands",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.combat.horde.prompt.reserved",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_horde_reactions.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Horde ahead. Engage or go around?",
                            },
                            ["TL"] = {
                                "May kuyog sa unahan. Lalaban o iiwas?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Crowd spotted. Call it.",
                            },
                            ["TL"] = {
                                "May nakitang grupo. Desisyunan mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Massed dead. Fight or bypass?",
                            },
                            ["TL"] = {
                                "Nagtitipong mga patay. Lalabanan o lalagpasan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Swarm blocking route. Your call.",
                            },
                            ["TL"] = {
                                "Harang ang kuyog sa daan. Ikaw ang masusunod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Large group. Stand and fight or slip past?",
                            },
                            ["TL"] = {
                                "Malaking grupo. Tatayo at lalaban o lulusot?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Herd ahead. Make a choice.",
                            },
                            ["TL"] = {
                                "Kawan sa harap. Pumili ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Horde present. Direct us.",
                            },
                            ["TL"] = {
                                "May kuyog dito. Pangunahan mo kami.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Too many in the open. Do we push or turn?",
                            },
                            ["TL"] = {
                                "Masyadong marami sa bukas na lugar. Susulong o liliko?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Mass contacts. Decision?",
                            },
                            ["TL"] = {
                                "Maraming kalaban. Ano'ng pasya?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Herd in path. Fight or avoid?",
                            },
                            ["TL"] = {
                                "May kuyog sa dinaraanan. Laban o iwas?",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_combat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
