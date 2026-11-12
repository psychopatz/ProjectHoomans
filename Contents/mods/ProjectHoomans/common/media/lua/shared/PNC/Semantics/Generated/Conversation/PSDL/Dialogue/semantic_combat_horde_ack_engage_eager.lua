-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.combat.horde.ack.engage_eager",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.ack.engage_eager",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_ack_engage_eager",
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
                ["responseTemplateID"] = "semantic.combat.horde.ack.engage_eager",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "ACK",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Ready to strike! Let's take them down.",
                            },
                            ["TL"] = {
                                "Handa nang humampas! Patumbahin natin sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Let's go! I've got your back.",
                            },
                            ["TL"] = {
                                "Tara na! Hawak ko ang likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Ready when you are! Charge!",
                            },
                            ["TL"] = {
                                "Handa na ako kapag handa ka na! Sugod!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Line them up! We can clear this whole pack.",
                            },
                            ["TL"] = {
                                "Pilahin sila! Kaya nating ubusin ang buong kawan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Eager and armed. Let's do some damage.",
                            },
                            ["TL"] = {
                                "Sabik at armado. Manalanta na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "I'm ready to fight! Moving in!",
                            },
                            ["TL"] = {
                                "Handa na akong lumaban! Susulong na!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Let's smash through them together!",
                            },
                            ["TL"] = {
                                "Durogin natin sila nang sabay!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Weapon's ready. Let's take the field!",
                            },
                            ["TL"] = {
                                "Handa ang armas. Angkinin natin ang labanan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Full speed ahead! They won't know what hit them.",
                            },
                            ["TL"] = {
                                "Buong bilis pasulong! Di nila malalaman ang tumama sa kanila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Hell yeah! Let's wipe them out.",
                            },
                            ["TL"] = {
                                "Oo naman! Ubusin natin sila.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_replies.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
