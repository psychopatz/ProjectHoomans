-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_greeting",
        ["id"] = "semantic.flow.greeting.opening.default.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.flow.greeting.opening.default.warm",
            ["sourcePath"] = "psdl/dialogue/conversation_greeting.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_flow_greeting_opening_default_warm",
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
                ["responseTemplateID"] = "semantic.flow.greeting.opening.default",
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
                                "Hey! It is good to see you.",
                            },
                            ["TL"] = {
                                "Uy! Mabuti at nakita kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Hey, good to see you in one piece.",
                            },
                            ["TL"] = {
                                "Uy, mabuti at buo ka pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Glad to see you. How are you holding up?",
                            },
                            ["TL"] = {
                                "Masaya akong nakita kita. Kumusta ang lagay mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "Hey. Really glad you made it back safe.",
                            },
                            ["TL"] = {
                                "Uy. Masaya talaga akong nakabalik ka nang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Back already? Good to have you around.",
                            },
                            ["TL"] = {
                                "Bumalik ka na agad? Mabuti at nandito ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "It's always a relief seeing you walk through.",
                            },
                            ["TL"] = {
                                "Laging nakakagaan ng loob makita kang dumarating.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Good to see you on your feet today.",
                            },
                            ["TL"] = {
                                "Mabuti at nakatayo ka pa rin ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "Hey there! How's your day been treating you?",
                            },
                            ["TL"] = {
                                "Uy! Kumusta ang araw mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Always good seeing a friendly face out here.",
                            },
                            ["TL"] = {
                                "Laging magandang makakita ng pamilyar na mukha rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Welcome back. Hope things were quiet out there.",
                            },
                            ["TL"] = {
                                "Maligayang pagbabalik. Sana tahimik lang sa labas.",
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
