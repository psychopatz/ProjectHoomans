-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["id"] = "semantic.combat.horde.deescalated",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.deescalated",
            ["sourcePath"] = "psdl/dialogue/companion_commands_combat.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_deescalated",
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
                ["responseTemplateID"] = "semantic.combat.horde.deescalated",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_horde_reactions.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "They're thinning out. Don't relax yet.",
                            },
                            ["TL"] = {
                                "Kumokonti sila. Huwag munang kampante.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Most of the swarm is down. Check stragglers.",
                            },
                            ["TL"] = {
                                "Bagsak na karamihan sa kuyog. Tignan ang mga naiwan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "The main wave is broken. Keep scanning.",
                            },
                            ["TL"] = {
                                "Nawasak na ang bulto. Tuloy sa pagmamasid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Fewer coming through now. Catch your breath.",
                            },
                            ["TL"] = {
                                "Kakaunti na lang ang dumarating. Huminga muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Herd's scattered. Clear the remaining few.",
                            },
                            ["TL"] = {
                                "Kalat na ang kuyog. Ubusin ang natitira.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "We weathered the bulk of them. Stay focused.",
                            },
                            ["TL"] = {
                                "Nalagpasan natin ang pinakamarami. Manatiling nakatutok.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Numbers are dropping. Keep the pressure on.",
                            },
                            ["TL"] = {
                                "Bumaba na ang bilang nila. Tuloy ang laban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "They're losing momentum. Finish them off.",
                            },
                            ["TL"] = {
                                "Nawawalan na sila ng pwersa. Tapusin na natin sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Only a handful left. Watch your spacing.",
                            },
                            ["TL"] = {
                                "Ilan-ilan na lang ang natitira. Bantayan ang distansya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "The rush is slowing down. Good work.",
                            },
                            ["TL"] = {
                                "Bumagal na ang pagdagsa. Maganda ang ginawa natin.",
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
