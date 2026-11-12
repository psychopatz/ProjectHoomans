-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_greeting",
        ["id"] = "semantic.flow.greeting.followup.friendly.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.flow.greeting.followup.friendly.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_greeting.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_flow_greeting_followup_friendly_neutral",
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
                ["responseTemplateID"] = "semantic.flow.greeting.followup.friendly",
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
                                "You're welcome. It's good to see you too.",
                            },
                            ["TL"] = {
                                "Walang anuman. Mabuti at nakita rin kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Anytime. Glad you're here.",
                            },
                            ["TL"] = {
                                "Kahit kailan. Masaya akong nandito ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Always glad to talk. Stay safe out there.",
                            },
                            ["TL"] = {
                                "Palaging masayang makausap ka. Mag-ingat ka sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "No problem. Holler if you need a hand.",
                            },
                            ["TL"] = {
                                "Walang problema. Tawagin mo ako kapag kailangan mo ng tulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Anytime, friend. Take care of yourself.",
                            },
                            ["TL"] = {
                                "Kahit kailan, kaibigan. Alagaan mo ang sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Glad we caught up. Catch you in a bit.",
                            },
                            ["TL"] = {
                                "Mabuti at nagkausap tayo. Magkita tayo mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "No trouble at all. Good to have you around.",
                            },
                            ["TL"] = {
                                "Walang problema talaga. Mabuti at nandito ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Sure thing. Watch yourself out there, alright?",
                            },
                            ["TL"] = {
                                "Oo naman. Mag-ingat ka sa labas, ha?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Take care. We'll talk again soon.",
                            },
                            ["TL"] = {
                                "Mag-iingat ka. Mag-usap tayo ulit mamaya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Always. Glad to see you on your feet.",
                            },
                            ["TL"] = {
                                "Palagi. Masaya akong maayos ang lagay mo.",
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
