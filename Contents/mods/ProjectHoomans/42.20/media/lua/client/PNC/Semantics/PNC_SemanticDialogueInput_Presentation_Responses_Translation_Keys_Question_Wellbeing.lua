-- Static semantic response template-key catalog for question_wellbeing.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.question.wellbeing.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingUnknown",
        ["semantic.question.wellbeing.panic"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingPanic",
        ["semantic.question.wellbeing.stress"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingStress",
        ["semantic.question.wellbeing.thirst"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingThirst",
        ["semantic.question.wellbeing.thirst_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingThirstAlt",
        ["semantic.question.wellbeing.hunger"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingHunger",
        ["semantic.question.wellbeing.hunger_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingHungerAlt",
        ["semantic.question.wellbeing.fatigue"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFatigue",
        ["semantic.question.wellbeing.fatigue_alt"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingFatigueAlt",
        ["semantic.question.wellbeing.injured"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingInjured",
        ["semantic.question.wellbeing.default"] =
            "UI_PNC_Conversation_Semantic_QuestionWellbeingDefault",
}

return keys

