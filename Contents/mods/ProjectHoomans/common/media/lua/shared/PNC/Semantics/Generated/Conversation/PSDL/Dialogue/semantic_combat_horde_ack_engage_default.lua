-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.combat.horde.ack.engage_default",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.ack.engage_default",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_ack_engage_default",
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
                ["responseTemplateID"] = "semantic.combat.horde.ack.engage_default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "ACK",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I'm with you. Let's go.",
                            },
                            ["TL"] = {
                                "Kasama mo ako. Tara.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Engaging now. Watch your side.",
                            },
                            ["TL"] = {
                                "Lalaban na ngayon. Bantayan ang tagiliran.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Right behind you into the fight.",
                            },
                            ["TL"] = {
                                "Nasa likod mo papunta sa laban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. We fight together.",
                            },
                            ["TL"] = {
                                "Naintindihan. Sabay tayong lalaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Moving in to strike.",
                            },
                            ["TL"] = {
                                "Lalapit para humampas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Let's clear the way.",
                            },
                            ["TL"] = {
                                "Hawiin natin ang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Ready for combat. Let's do this.",
                            },
                            ["TL"] = {
                                "Handa sa laban. Gawin na natin ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "On it. Target locked.",
                            },
                            ["TL"] = {
                                "Inaasikaso na. Nakatutok sa kalaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Moving forward to engage.",
                            },
                            ["TL"] = {
                                "Susulong para lumaban.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "With you all the way. Let's strike.",
                            },
                            ["TL"] = {
                                "Kasama mo sa buong laban. Sumugod na tayo.",
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
