-- Static semantic response template-key catalog for flow.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.flow.greeting.opening.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningFriendly",
        ["semantic.flow.greeting.opening.rain"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningRain",
        ["semantic.flow.greeting.opening.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpening",
        ["semantic.flow.greeting.opening.question.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestionFriendly",
        ["semantic.flow.greeting.opening.question.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingOpeningQuestion",
        ["semantic.flow.greeting.followup.friendly"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingFollowupFriendly",
        ["semantic.flow.greeting.followup.default"] =
            "UI_PNC_Conversation_Semantic_FlowGreetingFollowup",
        ["semantic.flow.weather.raining.default"] =
            "UI_PNC_Conversation_Semantic_FlowWeatherRaining",
        ["semantic.flow.weather.clear.default"] =
            "UI_PNC_Conversation_Semantic_FlowWeatherClear",
        ["semantic.flow.weather.unknown.default"] =
            "UI_PNC_Conversation_Semantic_FlowWeatherUnknown",
}

return keys

