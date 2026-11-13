-- Static semantic response template-key catalog for question_knowledge.
-- The facade merges this bounded domain table into the public key namespace.

local keys = {
        ["semantic.question.knowledge.known"] =
            "UI_PNC_Conversation_Semantic_QuestionKnowledgeKnown",
        ["semantic.question.knowledge.unknown"] =
            "UI_PNC_Conversation_Semantic_QuestionKnowledgeUnknown",
}

return keys

