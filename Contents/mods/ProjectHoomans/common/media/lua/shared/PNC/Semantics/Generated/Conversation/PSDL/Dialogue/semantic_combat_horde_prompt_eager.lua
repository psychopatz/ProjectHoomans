-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["id"] = "semantic.combat.horde.prompt.eager",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.prompt.eager",
            ["sourcePath"] = "psdl/dialogue/companion_commands_combat.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_prompt_eager",
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
                ["responseTemplateID"] = "semantic.combat.horde.prompt.eager",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_horde_reactions.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's a hell of a crowd. We taking them?",
                            },
                            ["TL"] = {
                                "Ang dami nila. Susugod ba tayo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Big group ahead. Let's carve right through them.",
                            },
                            ["TL"] = {
                                "Malaking grupo sa unahan. Biyakin na natin sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Look at all those targets. You ready to swing?",
                            },
                            ["TL"] = {
                                "Tingnan mo ang dami ng target. Handa ka na bang humataw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We can take this pack. What's the call?",
                            },
                            ["TL"] = {
                                "Kaya natin ang grupong 'to. Ano'ng desisyon?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I say we clear them out right here. Ready?",
                            },
                            ["TL"] = {
                                "Linisin na natin sila rito mismo. Handa ka na?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "They're packed together nicely. Time to strike.",
                            },
                            ["TL"] = {
                                "Magkakadikit sila nang maayos. Oras na para sumugod.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I've got plenty of energy. Let's drop them.",
                            },
                            ["TL"] = {
                                "Marami pa akong lakas. Itumba na natin sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Crowd of dead ahead. Give the word and I charge.",
                            },
                            ["TL"] = {
                                "Kuyog ng mga patay sa unahan. Sabihin mo lang at susugod ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "We've got weapons and room. Let's do this.",
                            },
                            ["TL"] = {
                                "May sandata at espasyo tayo. Labanan na natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Let's crack some skulls. We fighting or what?",
                            },
                            ["TL"] = {
                                "Magbasag tayo ng bungo. Lalaban ba tayo o ano?",
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
