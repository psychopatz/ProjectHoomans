-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["id"] = "semantic.combat.horde.started",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.started",
            ["sourcePath"] = "psdl/dialogue/companion_commands_combat.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_started",
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
                ["responseTemplateID"] = "semantic.combat.horde.started",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_horde_reactions.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "That's a lot of them. Stay sharp.",
                            },
                            ["TL"] = {
                                "Ang dami nila. Mag-ingat tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "We've got a whole crowd moving in. Eyes open.",
                            },
                            ["TL"] = {
                                "May malaking grupo na paparating. Magmatyag.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Horde spotted! Check your exits.",
                            },
                            ["TL"] = {
                                "May kuyog! Tignan ang mga labasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Too many bodies out there. Watch the perimeter.",
                            },
                            ["TL"] = {
                                "Masyado silang marami sa labas. Bantayan ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "They're grouping up. Form a line.",
                            },
                            ["TL"] = {
                                "Nagsasama-sama sila. Ayusin ang hanay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Sound drew a swarm. Get ready.",
                            },
                            ["TL"] = {
                                "Nakaakit ng kuyog ang ingay. Humanda.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Look at that herd. Stay close.",
                            },
                            ["TL"] = {
                                "Tingnan mo ang kawan na 'yan. Dumikit ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Mass contacts coming from down the street.",
                            },
                            ["TL"] = {
                                "Napakaraming papalapit mula sa kalsada.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Here they come. Don't let them flank us.",
                            },
                            ["TL"] = {
                                "Heto na sila. Huwag silang hayaang pumaligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Big group incoming. Watch each other's backs.",
                            },
                            ["TL"] = {
                                "Malaking grupo ang dumarating. Bantayan ang likod ng bawat isa.",
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
