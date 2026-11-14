-- Static semantic response template-key catalog for flow.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["flow.greeting.opening.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningFriendly",
        ["flow.greeting.opening.rain"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningRain",
        ["flow.greeting.opening.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpening",
        ["flow.greeting.opening.question.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestionFriendly",
        ["flow.greeting.opening.question.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestion",
        ["flow.greeting.followup.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingFollowupFriendly",
        ["flow.greeting.followup.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingFollowup",
        ["semantic.flow.weather.raining.default"] =
            "UI_PNC_Conversation_Semantic_FlowWeatherRaining",
        ["semantic.flow.weather.clear.default"] =
            "UI_PNC_Conversation_Semantic_FlowWeatherClear",
        ["semantic.flow.weather.unknown.default"] =
            "UI_PNC_Conversation_Semantic_FlowWeatherUnknown",
}

return keys

