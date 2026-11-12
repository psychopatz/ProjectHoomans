-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_greeting",
        ["id"] = "semantic.flow.greeting.opening.friendly.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.flow.greeting.opening.friendly.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_greeting.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_flow_greeting_opening_friendly_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "Good to see you.",
                            },
                            ["TL"] = {
                                "Mabuti at nakita kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "I was hoping we'd cross paths today.",
                            },
                            ["TL"] = {
                                "Inaasahan kong magkikita tayo ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Good to see you. How's the camp holding?",
                            },
                            ["TL"] = {
                                "Mabuti at nakita kita. Kumusta ang kampo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "There you are. Ready for another day?",
                            },
                            ["TL"] = {
                                "Nandiyan ka pala. Handa na ba para sa isa pang araw?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Back again. How's the scavenging going?",
                            },
                            ["TL"] = {
                                "Bumalik ka ulit. Kumusta ang paghahanap?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Good to see you again. Need a hand with anything?",
                            },
                            ["TL"] = {
                                "Mabuti at nakita kita ulit. Kailangan mo ba ng tulong?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Hey there. Glad we ran into each other.",
                            },
                            ["TL"] = {
                                "Kumusta. Masaya akong nagkasalubong tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Morning! How are things on your end?",
                            },
                            ["TL"] = {
                                "Magandang umaga! Kumusta ang lagay sa parte mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Hey! What's the plan for today?",
                            },
                            ["TL"] = {
                                "Uy! Anong plano para sa araw na ito?",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Good to catch up. How are you doing?",
                            },
                            ["TL"] = {
                                "Mabuti at nagkausap tayo. Kumusta ka?",
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
