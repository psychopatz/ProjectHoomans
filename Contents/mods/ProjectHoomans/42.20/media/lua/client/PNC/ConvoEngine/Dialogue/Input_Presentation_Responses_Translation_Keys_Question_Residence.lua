-- Static semantic response template-key catalog for question_residence.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.question.residence.known"] =
            "UI_PNC_Conversation_Semantic_QuestionResidenceKnown",
        ["semantic.question.residence.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionResidenceUnknown",
}

return keys

