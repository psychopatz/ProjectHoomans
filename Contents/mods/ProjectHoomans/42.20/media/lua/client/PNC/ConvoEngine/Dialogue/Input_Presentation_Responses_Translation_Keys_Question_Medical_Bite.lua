-- Static semantic response template-key catalog for question_medical_bite.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.question.medical_bite.positive"] =
            "UI_PNC_Conversation_Semantic_QuestionMedicalBitePositive",
        ["semantic.question.medical_bite.negative"] =
            "UI_PNC_Conversation_Semantic_QuestionMedicalBiteNegative",
        ["semantic.question.medical_bite.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionMedicalBiteUnknown",
}

return keys

