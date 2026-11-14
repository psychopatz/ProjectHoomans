-- Generated Conversation discovery index; do not edit by hand.
return {
    ["question.identity"] = {
        ["dependents"] = {
            "question.identity.known",
            "response_pool.question.identity",
            "social.core_identity",
        },
        ["domain"] = "core_knowledge_identity",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/UI/Dialogue/CoreIdentity",
        },
        ["id"] = "question.identity",
        ["kind"] = "dialogue",
        ["source"] = "dialogue/core_knowledge_identity/question_identity.json",
    },
    ["question.identity.known"] = {
        ["domain"] = "core_knowledge_identity",
        ["generated"] = {
            "PsychopatzCore/ConvoEngine/Dialogue/CoreKnowledgeIdentity",
        },
        ["id"] = "question.identity.known",
        ["kind"] = "dialogue",
        ["related"] = {
            "question.identity",
        },
        ["source"] = "dialogue/core_knowledge_identity/question_identity_known.json",
    },
}
