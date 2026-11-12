-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["id"] = "semantic.combat.horde.choice.engage",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.choice.engage",
            ["sourcePath"] = "psdl/dialogue/companion_commands_combat.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_choice_engage",
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
                ["responseTemplateID"] = "semantic.combat.horde.choice.engage",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_horde_reactions.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Take them.",
                            },
                            ["TL"] = {
                                "Sugurin natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We fight. Weapons up.",
                            },
                            ["TL"] = {
                                "Lalaban tayo. Itaas ang sandata.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Engage. Clear them all.",
                            },
                            ["TL"] = {
                                "Sugod. Ubusin silang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Stand and fight. Don't break line.",
                            },
                            ["TL"] = {
                                "Tumayo at lumaban. Huwag sirain ang linya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Let's take them down right here.",
                            },
                            ["TL"] = {
                                "Itumba na natin sila rito mismo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Strike now. Watch each other's sides.",
                            },
                            ["TL"] = {
                                "Tira na ngayon. Bantayan ang gilid ng isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "We're clearing this herd. Let's go.",
                            },
                            ["TL"] = {
                                "Lilinisin natin ang kuyog na 'to. Tara.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Cut them down one by one.",
                            },
                            ["TL"] = {
                                "Hiwain sila isa-isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Fight through them. Forward.",
                            },
                            ["TL"] = {
                                "Lusubin natin sila. Pasulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Take the fight to them.",
                            },
                            ["TL"] = {
                                "Harapin natin ang laban.",
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
