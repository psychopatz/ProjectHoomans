-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_greeting",
        ["id"] = "semantic.flow.greeting.followup.default.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.flow.greeting.followup.default.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_greeting.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_flow_greeting_followup_default_neutral",
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
                ["responseTemplateID"] = "semantic.flow.greeting.followup.default",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/greeting.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "You're welcome. Take care.",
                            },
                            ["TL"] = {
                                "Walang anuman. Mag-iingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "No trouble. Stay safe.",
                            },
                            ["TL"] = {
                                "Walang problema. Manatiling ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Anytime. Watch your back out there.",
                            },
                            ["TL"] = {
                                "Kahit kailan. Mag-ingat ka sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Don't mention it. See you around.",
                            },
                            ["TL"] = {
                                "Wala 'yon. Magkikita pa tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Glad to help. Take it easy.",
                            },
                            ["TL"] = {
                                "Masayang nakatulong. Dahan-dahan lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "All right. Stay alert today.",
                            },
                            ["TL"] = {
                                "Sige. Maging alerto ka ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "No problem at all. Be careful.",
                            },
                            ["TL"] = {
                                "Walang anuman talaga. Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Sure thing. Keep your eyes open.",
                            },
                            ["TL"] = {
                                "Oo naman. Buksan mo ang mga mata mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Take care of yourself out there.",
                            },
                            ["TL"] = {
                                "Alagaan mo ang sarili mo sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Until next time. Stay safe.",
                            },
                            ["TL"] = {
                                "Hanggang sa muli. Manatiling ligtas.",
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
