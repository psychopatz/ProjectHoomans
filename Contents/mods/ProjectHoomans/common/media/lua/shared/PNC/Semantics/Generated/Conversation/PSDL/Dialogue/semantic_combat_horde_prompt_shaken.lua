-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["id"] = "semantic.combat.horde.prompt.shaken",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.prompt.shaken",
            ["sourcePath"] = "psdl/dialogue/companion_commands_combat.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_prompt_shaken",
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
                ["responseTemplateID"] = "semantic.combat.horde.prompt.shaken",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_horde_reactions.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "God... that's a lot. Are we really fighting all of them?",
                            },
                            ["TL"] = {
                                "Diyos ko... ang dami nila. Lalabanan talaga natin lahat 'yan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Look at the size of that crowd... can we go around?",
                            },
                            ["TL"] = {
                                "Tingnan mo ang laki ng kuyog... pwede ba tayong umikot?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "They'll swarm us if we step out there. Please, let's retreat.",
                            },
                            ["TL"] = {
                                "Kukuyugin nila tayo kapag lumabas tayo. Pakiusap, umatras tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "There are way too many... my hands are shaking.",
                            },
                            ["TL"] = {
                                "Masyado silang marami... nanginginig ang mga kamay ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "We can't handle this many at once. Can we slip away?",
                            },
                            ["TL"] = {
                                "Hindi natin kaya ang ganyan karami nang sabay. Pwede bang tumakas?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Jesus, don't shoot... they'll tear us apart.",
                            },
                            ["TL"] = {
                                "Diyos ko, huwag kang puputok... pupunitin nila tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Are we seriously thinking of fighting that horde?",
                            },
                            ["TL"] = {
                                "Seryoso ba tayong lalabanan ang kuyog na 'yan?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I don't think we survive that fight. Let's run.",
                            },
                            ["TL"] = {
                                "Sa tingin ko hindi tayo mabubuhay sa laban na 'yan. Tumakbo na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Too many rottens... what do you want to do?",
                            },
                            ["TL"] = {
                                "Masyadong maraming bulok... ano'ng gusto mong gawin?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "That swarm is terrifying. Tell me we're bypassing it.",
                            },
                            ["TL"] = {
                                "Nakakatakot ang kuyog na 'yan. Sabihin mong iiwasan natin.",
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
