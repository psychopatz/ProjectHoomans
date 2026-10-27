-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "flow",
        ["id"] = "semantic.flow.weather.raining",
        ["variants"] = {
            {
                ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                ["id"] = "semantic.flow.weather.raining.dataset.contextual_switch",
                ["metadata"] = {
                    ["reviewed"] = true,
                    ["sourceRefs"] = {
                        "MASSIVE",
                        "SGD",
                    },
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_DatasetWeatherContextualSwitch",
                },
                ["plan"] = {
                    ["dialogueAct"] = "WEATHER_REPORT",
                    ["groundedFactRefs"] = {
                        "world.weather.raining",
                    },
                    ["personalityStyle"] = "contextual",
                    ["referenceSubject"] = nil,
                    ["referenceTopic"] = nil,
                    ["sourcePoolID"] = "semantic.flow.weather.raining",
                    ["tone"] = "conversational",
                    ["topic"] = "WEATHER",
                    ["turns"] = {
                        {
                            ["continuation"] = "continue",
                            ["id"] = "dataset_contextual_weather_switch",
                            ["segments"] = {
                                {
                                    ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                                    ["kind"] = "translation",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWeatherContextualSwitch",
                                    ["translationArgs"] = {
                                    },
                                },
                            },
                        },
                    },
                    ["uncertainty"] = "known",
                },
                ["priority"] = 4,
                ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWeatherContextualSwitch",
                ["when"] = {
                    ["pattern"] = "pnc.dataset.question.weather.can_we_talk_about_the_weather",
                },
            },
        },
    },
}
