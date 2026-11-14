-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "companion_commands_lifecycle",
        ["exchangeFamily"] = {
            ["familyID"] = "command.stop_following.rejected",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "I can't stop following right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.command.stop_following.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I can't stop following right now.",
                                        "It's too dangerous to split up. I'm staying with you.",
                                        "I won't leave you alone against that swarm.",
                                        "We need to stay together to survive this. Refusing to halt.",
                                        "If I stop following here, I'll be completely cut off.",
                                        "Cannot halt here. Too many dead around us.",
                                        "I'm sticking with you until we reach actual cover.",
                                        "Splitting up now will get us killed. I'm following.",
                                        "Unable to break follow in active combat.",
                                        "Order rejected. We survive together or not at all.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako makapaghinto sa pagsunod ngayon.",
                                        "Masyadong mapanganib maghiwalay. Sasama ako sa 'yo.",
                                        "Di kita iiwan mag-isa laban sa kawang 'yan.",
                                        "Kailangan nating magsama para mabuhay. Tumatangging huminto.",
                                        "Kapag huminto ako rito, ganap akong mahihiwalay.",
                                        "Di makahinto rito. Napakaraming patay sa paligid.",
                                        "Didikit ako sa 'yo hanggang makarating sa tunay na silong.",
                                        "Ikinamamatay ang paghihiwalay ngayon. Susunod ako.",
                                        "Di makatigil sa pagsunod habang may bakbakan.",
                                        "Tinatanggihan ang utos. Sabay tayong mabubuhay o mamamatay.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "command.stop_following",
            ["textRoles"] = {
                {
                    ["fallback"] = "I can't stop following right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.command.stop_following.rejected.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I can't stop following right now.",
                            "It's too dangerous to split up. I'm staying with you.",
                            "I won't leave you alone against that swarm.",
                            "We need to stay together to survive this. Refusing to halt.",
                            "If I stop following here, I'll be completely cut off.",
                            "Cannot halt here. Too many dead around us.",
                            "I'm sticking with you until we reach actual cover.",
                            "Splitting up now will get us killed. I'm following.",
                            "Unable to break follow in active combat.",
                            "Order rejected. We survive together or not at all.",
                        },
                        ["TL"] = {
                            "Hindi ako makapaghinto sa pagsunod ngayon.",
                            "Masyadong mapanganib maghiwalay. Sasama ako sa 'yo.",
                            "Di kita iiwan mag-isa laban sa kawang 'yan.",
                            "Kailangan nating magsama para mabuhay. Tumatangging huminto.",
                            "Kapag huminto ako rito, ganap akong mahihiwalay.",
                            "Di makahinto rito. Napakaraming patay sa paligid.",
                            "Didikit ako sa 'yo hanggang makarating sa tunay na silong.",
                            "Ikinamamatay ang paghihiwalay ngayon. Susunod ako.",
                            "Di makatigil sa pagsunod habang may bakbakan.",
                            "Tinatanggihan ang utos. Sabay tayong mabubuhay o mamamatay.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "command.stop_following.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "command.stop_following.rejected",
            ["sourcePath"] = "adopters/hoomans/dialogue/companion_commands_lifecycle/command_stop_following_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CompanionCommandsLifecycle__82a5588b",
        ["namespace"] = "command.stop_following",
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
                ["responseAct"] = "REPLY",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/command/lifecycle/stop_following.json",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I can't stop following right now.",
                                        "It's too dangerous to split up. I'm staying with you.",
                                        "I won't leave you alone against that swarm.",
                                        "We need to stay together to survive this. Refusing to halt.",
                                        "If I stop following here, I'll be completely cut off.",
                                        "Cannot halt here. Too many dead around us.",
                                        "I'm sticking with you until we reach actual cover.",
                                        "Splitting up now will get us killed. I'm following.",
                                        "Unable to break follow in active combat.",
                                        "Order rejected. We survive together or not at all.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako makapaghinto sa pagsunod ngayon.",
                                        "Masyadong mapanganib maghiwalay. Sasama ako sa 'yo.",
                                        "Di kita iiwan mag-isa laban sa kawang 'yan.",
                                        "Kailangan nating magsama para mabuhay. Tumatangging huminto.",
                                        "Kapag huminto ako rito, ganap akong mahihiwalay.",
                                        "Di makahinto rito. Napakaraming patay sa paligid.",
                                        "Didikit ako sa 'yo hanggang makarating sa tunay na silong.",
                                        "Ikinamamatay ang paghihiwalay ngayon. Susunod ako.",
                                        "Di makatigil sa pagsunod habang may bakbakan.",
                                        "Tinatanggihan ang utos. Sabay tayong mabubuhay o mamamatay.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REPLY",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "command.stop_following.rejected",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I can't stop following right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.command.stop_following.rejected.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "adopters/hoomans/dialogue/companion_commands_lifecycle/command_stop_following_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I can't stop following right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.command.stop_following.rejected.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I can't stop following right now.",
                        "It's too dangerous to split up. I'm staying with you.",
                        "I won't leave you alone against that swarm.",
                        "We need to stay together to survive this. Refusing to halt.",
                        "If I stop following here, I'll be completely cut off.",
                        "Cannot halt here. Too many dead around us.",
                        "I'm sticking with you until we reach actual cover.",
                        "Splitting up now will get us killed. I'm following.",
                        "Unable to break follow in active combat.",
                        "Order rejected. We survive together or not at all.",
                    },
                    ["TL"] = {
                        "Hindi ako makapaghinto sa pagsunod ngayon.",
                        "Masyadong mapanganib maghiwalay. Sasama ako sa 'yo.",
                        "Di kita iiwan mag-isa laban sa kawang 'yan.",
                        "Kailangan nating magsama para mabuhay. Tumatangging huminto.",
                        "Kapag huminto ako rito, ganap akong mahihiwalay.",
                        "Di makahinto rito. Napakaraming patay sa paligid.",
                        "Didikit ako sa 'yo hanggang makarating sa tunay na silong.",
                        "Ikinamamatay ang paghihiwalay ngayon. Susunod ako.",
                        "Di makatigil sa pagsunod habang may bakbakan.",
                        "Tinatanggihan ang utos. Sabay tayong mabubuhay o mamamatay.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
