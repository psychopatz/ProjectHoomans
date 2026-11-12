-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.queued.trusted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stop_following.queued.trusted",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[32]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_stop_following_queued_trusted",
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
                ["responseTemplateID"] = "semantic.command.stop_following.queued.trusted",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Understood, I'll stop. I trust your solo judgment.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko, titigil ako. Tiwala ako sa sarili mong desisyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I'll hold here, partner. Come back safe.",
                            },
                            ["TL"] = {
                                "Dito muna ako, kasama. Bumalik kang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Stopping follow. I know you can handle what's ahead.",
                            },
                            ["TL"] = {
                                "Hihinto sa pagsunod. Alam kong kaya mo ang nasa unahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. I'll secure this spot while you work.",
                            },
                            ["TL"] = {
                                "Naintindihan. Seselyuhan ko ang pwestong ito habang nagtatrabaho ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "I'll let you move alone, friend. Shout if you need backup.",
                            },
                            ["TL"] = {
                                "Hahayaan kitang mag-isang lumakad, kaibigan. Sumigaw kapag kailangan mo ng saklolo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Stopping here. You've earned my complete trust.",
                            },
                            ["TL"] = {
                                "Hihinto rito. Nakuha mo na ang buo kong tiwala.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Halting follow. Watch your corners out there.",
                            },
                            ["TL"] = {
                                "Hihinto sa pagsunod. Bantayan ang mga kanto sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "I'll hold this ground for you until you return, partner.",
                            },
                            ["TL"] = {
                                "Hahawakan ko ang pwestong ito para sa 'yo hanggang sa bumalik ka, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Understood. Stopping here and maintaining watch.",
                            },
                            ["TL"] = {
                                "Naiintindihan ko. Hihinto rito at magbabantay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "I trust you know what you're doing. Standing down.",
                            },
                            ["TL"] = {
                                "Tiwala akong alam mo ang ginagawa mo. Uurong sa pwesto.",
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
