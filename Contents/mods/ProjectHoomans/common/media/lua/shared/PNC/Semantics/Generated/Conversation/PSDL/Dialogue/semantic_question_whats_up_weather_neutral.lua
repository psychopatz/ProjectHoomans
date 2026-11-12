-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.weather.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.weather.neutral",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_weather_neutral",
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
                ["contentOwner"] = "projecthoomans.dialogue_content.conversation",
                ["responseTemplateID"] = "semantic.question.whats_up.weather",
                ["sourceSurface"] = "tools/semantic_harness/codebuilder/sources/conversation/content/conversation.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["text"] = {
                            ["EN"] = {
                                "The weather is the main thing on my mind right now.",
                            },
                            ["TL"] = {
                                "Ang panahon ang pangunahing iniisip ko ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["text"] = {
                            ["EN"] = {
                                "Looks like the skies might turn on us soon.",
                            },
                            ["TL"] = {
                                "Mukhang sasama ang lagay ng panahon maya-maya.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["text"] = {
                            ["EN"] = {
                                "Watching the clouds roll in. Hope we stay dry.",
                            },
                            ["TL"] = {
                                "Tinitingnan ang pagdating ng mga ulap. Sana manatiling tuyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["text"] = {
                            ["EN"] = {
                                "Cold wind's picking up today. Harder to stay warm.",
                            },
                            ["TL"] = {
                                "Lumalakas ang malamig na hangin ngayon. Mahirap magpainit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["text"] = {
                            ["EN"] = {
                                "Can't afford to get soaked out here without a fire.",
                            },
                            ["TL"] = {
                                "Hindi puwedeng mabasa rito kung walang apoy.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hoping the rain holds off until we finish our runs.",
                            },
                            ["TL"] = {
                                "Sana huwag munang umulan hanggang sa matapos ang mga lakad natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["text"] = {
                            ["EN"] = {
                                "Weather's unpredictable lately. Keeping an eye on the sky.",
                            },
                            ["TL"] = {
                                "Pabago-bago ang panahon kamakailan. Laging nakatingin sa langit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["text"] = {
                            ["EN"] = {
                                "Temperature is dropping fast. Gonna be a cold night.",
                            },
                            ["TL"] = {
                                "Bumababa nang mabilis ang temperatura. Magiging malamig ang gabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["text"] = {
                            ["EN"] = {
                                "Just thinking about finding a roof before the weather hits.",
                            },
                            ["TL"] = {
                                "Iniisip ko lang makahanap ng bubong bago dumating ang ulan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["text"] = {
                            ["EN"] = {
                                "Clear skies for now, but you never know when it'll shift.",
                            },
                            ["TL"] = {
                                "Maliwanag pa naman ngayon, pero hindi mo masasabi kung kailan magbabago.",
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
        ["sourceShard"] = "psdl/dialogue/conversation_whats_up.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
