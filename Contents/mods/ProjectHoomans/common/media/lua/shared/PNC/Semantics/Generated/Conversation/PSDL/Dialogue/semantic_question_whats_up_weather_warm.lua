-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "conversation_whats_up",
        ["id"] = "semantic.question.whats_up.weather.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.whats_up.weather.warm",
            ["sourcePath"] = "psdl/dialogue/conversation_whats_up.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_whats_up_weather_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "REACT",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["text"] = {
                            ["EN"] = {
                                "The weather is the main thing on my mind right now. How are you holding up?",
                            },
                            ["TL"] = {
                                "Ang panahon ang pangunahing iniisip ko ngayon. Kumusta ka naman?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["text"] = {
                            ["EN"] = {
                                "Chilly out here today. Make sure you bundle up and stay warm, alright?",
                            },
                            ["TL"] = {
                                "Malamig dito ngayon. Magsuot ka ng makapal at magpainit, ha?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["text"] = {
                            ["EN"] = {
                                "Looks like rain might fall. Let's make sure our dry clothes stay safe.",
                            },
                            ["TL"] = {
                                "Mukhang uulan. Siguraduhin nating ligtas ang mga tuyo nating damit.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["text"] = {
                            ["EN"] = {
                                "I was just watching the clouds. Hope you've got a warm fire waiting for you.",
                            },
                            ["TL"] = {
                                "Pinagmamasdan ko ang mga ulap. Sana may mainit kang masisilungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["text"] = {
                            ["EN"] = {
                                "Cold wind today, but seeing your face makes it feel a bit warmer.",
                            },
                            ["TL"] = {
                                "Malamig ang hangin, pero nakakabawas ng ginaw na makita ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["text"] = {
                            ["EN"] = {
                                "Hoping the bad weather passes over us without trouble. Stay dry out there.",
                            },
                            ["TL"] = {
                                "Sana lumampas ang masamang panahon nang walang gulo. Manatiling tuyo sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["text"] = {
                            ["EN"] = {
                                "Weather's rough, but we'll weather any storm together, my friend.",
                            },
                            ["TL"] = {
                                "Mabigat ang panahon, pero kakayanin natin anumang bagyo, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["text"] = {
                            ["EN"] = {
                                "If it starts pouring, come share some shelter with us.",
                            },
                            ["TL"] = {
                                "Kapag nagsimulang bumuhos ang ulan, sumilong ka kasama namin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["text"] = {
                            ["EN"] = {
                                "Just keeping an eye on the sky so none of our people get caught in the wet.",
                            },
                            ["TL"] = {
                                "Binabantayan ang langit para walang mabasa sa mga kasamahan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["text"] = {
                            ["EN"] = {
                                "Gloomy day outside, but good company makes all the difference.",
                            },
                            ["TL"] = {
                                "Madilim ang araw sa labas, pero iba talaga kapag may magandang kasama.",
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
