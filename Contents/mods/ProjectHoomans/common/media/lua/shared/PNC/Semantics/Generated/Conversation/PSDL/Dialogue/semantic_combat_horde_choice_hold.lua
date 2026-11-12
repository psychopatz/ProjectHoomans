-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_combat",
        ["id"] = "semantic.combat.horde.choice.hold",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.choice.hold",
            ["sourcePath"] = "psdl/dialogue/companion_commands_combat.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_choice_hold",
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
                ["responseTemplateID"] = "semantic.combat.horde.choice.hold",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/event/combat_horde_reactions.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Hold for now.",
                            },
                            ["TL"] = {
                                "Hinto muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Stay put. Watch their movement.",
                            },
                            ["TL"] = {
                                "Diyan lang. Bantayan ang galaw nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Hold position and let them pass.",
                            },
                            ["TL"] = {
                                "Hawakan ang pwesto at hayaang lumampas sila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Wait here. Don't make a sound.",
                            },
                            ["TL"] = {
                                "Maghintay rito. Huwag gagawa ng tunog.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Hold up. See which way they drift.",
                            },
                            ["TL"] = {
                                "Tigil muna. Tignan kung saan sila papunta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Freeze. Don't reveal our position.",
                            },
                            ["TL"] = {
                                "Huwag gagalaw. Huwag ilantad ang pwesto natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Keep low and hold here.",
                            },
                            ["TL"] = {
                                "Yumuko at manatili rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Stay behind cover for a moment.",
                            },
                            ["TL"] = {
                                "Manatili sa kublihan sandali.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Hold the line. Wait for the signal.",
                            },
                            ["TL"] = {
                                "Hawakan ang linya. Hintayin ang senyas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Wait and observe before moving.",
                            },
                            ["TL"] = {
                                "Maghintay at magmasid bago kumilos.",
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
