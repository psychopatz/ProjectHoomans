-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stay.queued.trusted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stay.queued.trusted",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[25]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_stay_queued_trusted",
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
                ["responseTemplateID"] = "semantic.command.stay.queued.trusted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stay.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "All right, I'll stay. Watch your back out there.",
                            },
                            ["TL"] = {
                                "Sige, mananatili ako. Bantayan mo ang likod mo sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I trust your plan. I'll secure this position.",
                            },
                            ["TL"] = {
                                "Tiwala ako sa plano mo. Seselyuhan ko ang pwestong ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Holding this ground for both of us, partner.",
                            },
                            ["TL"] = {
                                "Hahawakan ko ang pwestong ito para sa atin, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I won't let anything breach this spot while you're away.",
                            },
                            ["TL"] = {
                                "Walang makakapasok dito habang wala ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll stay right here until you call.",
                            },
                            ["TL"] = {
                                "Naintindihan. Dito lang ako hanggang tawagin mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "You can count on me to hold this room, friend.",
                            },
                            ["TL"] = {
                                "Makaaasa ka sa akin na bantayan ang kwartong ito, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Holding this vantage point. Be careful out there.",
                            },
                            ["TL"] = {
                                "Hawak ang magandang tanawin na ito. Mag-ingat ka sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll be right here when you return, partner. Stay alive.",
                            },
                            ["TL"] = {
                                "Narito lang ako pagbalik mo, kasama. Manatiling buhay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Trusting you to come back safe. Holding the line.",
                            },
                            ["TL"] = {
                                "Nagtitiwala akong babalik kang ligtas. Hawak ang linya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll hold this post with my life.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Babantayan ko ang posteng ito nang buong tapang.",
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
        ["sourceShard"] = "psdl/dialogue/companion_commands_lifecycle.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
