-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_greeting",
        ["id"] = "semantic.flow.greeting.opening.friendly.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.flow.greeting.opening.friendly.warm",
            ["sourcePath"] = "psdl/dialogue/conversation_greeting.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_flow_greeting_opening_friendly_warm",
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
                ["category"] = "projecthoomans:conversation_content",
                ["contentOwner"] = "projecthoomans.dialogue_content.commands_emotes",
                ["responseTemplateID"] = "semantic.flow.greeting.opening.friendly",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/greeting.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "There you are! Good to see you.",
                            },
                            ["TL"] = {
                                "Nandiyan ka pala! Mabuti at nakita kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "I was hoping I'd run into you today.",
                            },
                            ["TL"] = {
                                "Umasa akong makakasalubong kita ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Back so soon? Glad you're safe.",
                            },
                            ["TL"] = {
                                "Bumalik ka agad? Mabuti at ligtas ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "I was hoping you'd come back in one piece.",
                            },
                            ["TL"] = {
                                "Umasa akong babalik ka nang buo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "There you are. You doing alright today?",
                            },
                            ["TL"] = {
                                "Nandiyan ka pala. Maayos ka ba ngayon?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Good to see you. Pull up a chair.",
                            },
                            ["TL"] = {
                                "Mabuti at nakita kita. Umupo ka muna.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Always makes my day better seeing you back safe.",
                            },
                            ["TL"] = {
                                "Palaging gumaganda ang araw ko kapag nakikita kitang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hey there! Really glad you're around today.",
                            },
                            ["TL"] = {
                                "Uy! Masaya talaga akong nandito ka ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "It's good to see your face. How're you feeling?",
                            },
                            ["TL"] = {
                                "Mabuting makita ang mukha mo. Kumusta ang pakiramdam mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Welcome back, my friend. Good to see you.",
                            },
                            ["TL"] = {
                                "Maligayang pagbabalik, kaibigan. Mabuti at nakita kita.",
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
        ["sourceShard"] = "psdl/dialogue/conversation_greeting.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
