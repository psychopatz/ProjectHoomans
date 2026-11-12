-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["id"] = "semantic.combat.horde.prompt.default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.prompt.default",
            ["sourcePath"] = "psdl/dialogue/companion_commands_combat.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_prompt_default",
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
                ["responseTemplateID"] = "semantic.combat.horde.prompt.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_horde_reactions.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's a lot of them. We fighting or going around?",
                            },
                            ["TL"] = {
                                "Ang dami nila. Lalaban ba tayo o iiwas?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Big swarm ahead. What's the plan?",
                            },
                            ["TL"] = {
                                "Malaking kuyog sa unahan. Ano'ng plano?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Whole herd in our way. Do we push through or find another path?",
                            },
                            ["TL"] = {
                                "Buong kawan ang nakaharang. Susugod ba tayo o maghahanap ng ibang daan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Look at the street. Are we engaging or avoiding?",
                            },
                            ["TL"] = {
                                "Tingnan mo ang kalsada. Lalabanan ba natin o iiwasan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Infected group is large. How do you want to handle this?",
                            },
                            ["TL"] = {
                                "Malaki ang grupo ng infected. Paano mo gustong harapin 'to?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Crowd ahead of us. Should we fight or sneak past?",
                            },
                            ["TL"] = {
                                "May mga patay sa harap natin. Lalaban ba tayo o lulusot nang tahimik?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "There's quite a crowd. What are we doing?",
                            },
                            ["TL"] = {
                                "Medyo marami sila. Ano'ng gagawin natin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "They're blocking the lane. Do we clear them or detour?",
                            },
                            ["TL"] = {
                                "Harang sila sa daan. Lilinisin ba natin o iikot tayo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Horde right in front. What do you want to do?",
                            },
                            ["TL"] = {
                                "Kuyog mismo sa harap. Ano'ng gusto mong gawin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "That's more than a few. Engage or back off?",
                            },
                            ["TL"] = {
                                "Higit pa sa iilan 'yan. Susugod o aatras?",
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
