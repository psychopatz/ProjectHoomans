-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["id"] = "semantic.command.stop_following.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.command.stop_following.rejected",
            ["sourcePath"] = "psdl/dialogue/companion_commands_lifecycle.json#records[34]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_command_stop_following_rejected",
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
                ["responseTemplateID"] = "semantic.command.stop_following.rejected",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["response"] = {
                ["act"] = "REPLY",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "I can't stop following right now.",
                            },
                            ["TL"] = {
                                "Hindi ako makapaghinto sa pagsunod ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "It's too dangerous to split up. I'm staying with you.",
                            },
                            ["TL"] = {
                                "Masyadong mapanganib maghiwalay. Sasama ako sa 'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "I won't leave you alone against that swarm.",
                            },
                            ["TL"] = {
                                "Di kita iiwan mag-isa laban sa kawang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "We need to stay together to survive this. Refusing to halt.",
                            },
                            ["TL"] = {
                                "Kailangan nating magsama para mabuhay. Tumatangging huminto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "If I stop following here, I'll be completely cut off.",
                            },
                            ["TL"] = {
                                "Kapag huminto ako rito, ganap akong mahihiwalay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Cannot halt here. Too many dead around us.",
                            },
                            ["TL"] = {
                                "Di makahinto rito. Napakaraming patay sa paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "I'm sticking with you until we reach actual cover.",
                            },
                            ["TL"] = {
                                "Didikit ako sa 'yo hanggang makarating sa tunay na silong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Splitting up now will get us killed. I'm following.",
                            },
                            ["TL"] = {
                                "Ikinamamatay ang paghihiwalay ngayon. Susunod ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Unable to break follow in active combat.",
                            },
                            ["TL"] = {
                                "Di makatigil sa pagsunod habang may bakbakan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Order rejected. We survive together or not at all.",
                            },
                            ["TL"] = {
                                "Tinatanggihan ang utos. Sabay tayong mabubuhay o mamamatay.",
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
