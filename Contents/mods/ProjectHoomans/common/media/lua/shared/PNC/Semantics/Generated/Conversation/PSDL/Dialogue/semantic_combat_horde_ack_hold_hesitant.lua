-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_replies",
        ["id"] = "semantic.combat.horde.ack.hold_hesitant",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.combat.horde.ack.hold_hesitant",
            ["sourcePath"] = "psdl/dialogue/companion_commands_replies.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_combat_horde_ack_hold_hesitant",
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
                ["responseTemplateID"] = "semantic.combat.horde.ack.hold_hesitant",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/replies.json",
            },
            ["response"] = {
                ["act"] = "ACK",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Okay. Holding here.",
                            },
                            ["TL"] = {
                                "Sige. Dito muna ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Staying put. I hope they don't see us.",
                            },
                            ["TL"] = {
                                "Dito lang ako. Sana di nila tayo makita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Holding position... please be quiet.",
                            },
                            ["TL"] = {
                                "Hawak ang pwesto... pakiusap tumahimik.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Holding ground. Heart's pounding.",
                            },
                            ["TL"] = {
                                "Hawak ang pwesto. Lumalakas ang tibok ng puso ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'll wait here, but let's be careful.",
                            },
                            ["TL"] = {
                                "Maghihintay ako rito, pero mag-ingat tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Staying still. Don't make a sound.",
                            },
                            ["TL"] = {
                                "Walang kikilos. Huwag gagawa ng tunog.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Holding... waiting for your call.",
                            },
                            ["TL"] = {
                                "Hawak muna... naghihintay sa utos mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Keeping low. I hope this works.",
                            },
                            ["TL"] = {
                                "Nakayuko. Sana magtagumpay ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Holding here. Watching their claws.",
                            },
                            ["TL"] = {
                                "Hawak dito. Binabantayan ang kuko nila.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood... staying frozen right here.",
                            },
                            ["TL"] = {
                                "Naintindihan... di gagalaw dito mismo.",
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
