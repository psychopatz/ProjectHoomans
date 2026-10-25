-- Semantic response template-key resolver.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input
local Internal = Input.Internal or {}
Input.Internal = Internal

local BACKSTORY_KINDS = {
    former_job = "UI_PNC_Conversation_Semantic_QuestionBackstoryFormerJob",
    hometown = "UI_PNC_Conversation_Semantic_QuestionBackstoryHometown",
    education = "UI_PNC_Conversation_Semantic_QuestionBackstoryEducation",
    hobby = "UI_PNC_Conversation_Semantic_QuestionBackstoryHobby",
    family_background = "UI_PNC_Conversation_Semantic_QuestionBackstoryFamily",
    fear = "UI_PNC_Conversation_Semantic_QuestionBackstoryFear",
    tragedy = "UI_PNC_Conversation_Semantic_QuestionBackstoryTragedy",
}
local keys = Internal.SemanticTranslationKeys

local function semanticTranslationKey(response)
    local templateID = tostring(response and response.templateID or "")
    if string.sub(templateID, 1, 7) == "UI_PNC_" then
        return templateID
    end
    if templateID == "semantic.question.identity" then
        local fallback = tostring(response and response.fallback or "")
        if string.find(string.lower(fallback), "liars", 1, true) then
            return "UI_PNC_Conversation_Semantic_QuestionIdentityWary"
        end
        if string.sub(fallback, 1, 4) == "I'm " then
            return "UI_PNC_Conversation_Semantic_QuestionIdentityKnown"
        end
        return "UI_PNC_Conversation_Semantic_QuestionIdentity"
    end
    if templateID == "semantic.question.identity.known" then
        return "UI_PNC_Conversation_Semantic_QuestionIdentityKnown"
    end
    if templateID == "semantic.question.backstory.known" then
        local args = response and response.args
        return BACKSTORY_KINDS[args and args.kind]
            or "UI_PNC_Conversation_Semantic_QuestionBackstoryKnown"
    end
    if templateID == "semantic.question.backstory.suspected" then
        return "UI_PNC_Conversation_Semantic_QuestionBackstorySuspected"
    end
    if templateID == "semantic.question.backstory.ambiguous" then
        return "UI_PNC_Conversation_Semantic_QuestionBackstoryAmbiguous"
    end
    if templateID == "semantic.question.backstory.refusal" then
        return "UI_PNC_Conversation_Semantic_QuestionBackstoryRefusal"
    end
    return keys[templateID]
end

Internal.SemanticTranslationKey = semanticTranslationKey

return semanticTranslationKey

