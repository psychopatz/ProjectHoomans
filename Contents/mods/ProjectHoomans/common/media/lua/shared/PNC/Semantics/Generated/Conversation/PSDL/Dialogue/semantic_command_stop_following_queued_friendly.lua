-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.queued.friendly",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stop_following.queued.friendly",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[30]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_stop_following_queued_friendly",
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
                ["responseTemplateID"] = "semantic.command.stop_following.queued.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Got it, I'll stop following. Take care out there, friend!",
                            },
                            ["TL"] = {
                                "Nakuha ko, titigil ako sa pagsunod. Mag-ingat ka sa labas, kaibigan!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Sure thing! I'll hold down this spot for you, partner.",
                            },
                            ["TL"] = {
                                "Walang anuman! Babantayan ko ang pwestong ito para sa 'yo, kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Happy to give you some space. Holler if you need me!",
                            },
                            ["TL"] = {
                                "Masayang bibigyan kita ng puwang. Tawagin mo ako kapag kailangan mo ako!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "I'll stop following here, friend. Be careful on your solo run.",
                            },
                            ["TL"] = {
                                "Hihinto ako sa pagsunod dito, kaibigan. Mag-ingat sa sarili mong lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Understood, partner! I'll be right here waiting.",
                            },
                            ["TL"] = {
                                "Naintindihan, kasama! Narito lang ako naghihintay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Stopping here with a smile. Don't be a stranger!",
                            },
                            ["TL"] = {
                                "Hihinto rito nang may ngiti. Magpakita ka agad!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Sure! I'll catch my breath while you scout ahead.",
                            },
                            ["TL"] = {
                                "Sige! Hihinga muna ako habang nagmamanman ka sa unahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "All right, friend! I'll stay put until you return.",
                            },
                            ["TL"] = {
                                "Sige, kaibigan! Dito lang ako hanggang makabalik ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Halting here. Good luck out there, partner!",
                            },
                            ["TL"] = {
                                "Hihinto rito. Magandang suwerte sa 'yo sa labas, kasama!",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "No worries! I'll stop following and guard our rear.",
                            },
                            ["TL"] = {
                                "Walang problema! Titigil sa pagsunod at babantayan ang likod.",
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
