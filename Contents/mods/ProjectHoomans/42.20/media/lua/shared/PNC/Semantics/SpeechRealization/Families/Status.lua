-- Status and greeting realization families.

local Builders = require
    "PNC/Semantics/PNC_SpeechRealization_FamilyBuilders"
local phraseFamily = Builders.phraseFamily
local canonicalContentStyleFamily = {
    -- Wording is owned by generated Conversation Content. Keep only the
    -- registry membership shell used by the existing style resolver.
    neutral = {},
    warm = {},
    terse = {},
    guarded = {},
}

return {
    ["semantic.flow.greeting.opening.default"] = {
        neutral = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingNeutral",
            fallback = "Hello. Good to see you.",
        },
        warm = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingWarm",
            fallback = "Hey! It is good to see you.",
        },
        terse = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingTerse",
            fallback = "Hello.",
        },
        guarded = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingGuarded",
            fallback = "State your business. Keep your distance.",
        },
    },
    ["semantic.flow.greeting.opening.friendly"] = {
        neutral = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingNeutral",
            fallback = "Hello. Good to see you.",
        },
        warm = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingWarm",
            fallback = "Hey! It is good to see you.",
        },
        terse = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingTerse",
            fallback = "Hello.",
        },
        guarded = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingGuarded",
            fallback = "State your business. Keep your distance.",
        },
    },
    ["semantic.flow.greeting.opening.question.default"] = {
        neutral = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionNeutral",
            fallback = "How have you been?",
        },
        warm = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionWarm",
            fallback = "How have you been holding up?",
        },
        terse = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionTerse",
            fallback = "You okay?",
        },
        guarded = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionGuarded",
            fallback = "How are things?",
        },
    },
    ["semantic.flow.greeting.opening.question.friendly"] = {
        neutral = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionNeutral",
            fallback = "How have you been?",
        },
        warm = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionWarm",
            fallback = "How have you been holding up?",
        },
        terse = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionTerse",
            fallback = "You okay?",
        },
        guarded = {
            key = "UI_PNC_Conversation_Semantic_RealizationGreetingQuestionGuarded",
            fallback = "How are things?",
        },
    },
    ["semantic.question.wellbeing.default"] = canonicalContentStyleFamily,
    ["semantic.question.wellbeing.injured"] = canonicalContentStyleFamily,
    ["semantic.question.wellbeing.dataset.getting_by"] = phraseFamily(
        "WellbeingGettingBy", "I'm getting by, one day at a time. How about you?",
        "I'm getting by. Thanks for asking.", "Getting by.",
        "I'm getting by. Leave it there."
    ),
    ["semantic.question.needs.offer.hunger"] = phraseFamily(
        "NeedsHunger", "Food would help, but I don't know the exact amount.",
        "Food would help, if you can spare it.", "I need food.",
        "I need food. Keep your distance."
    ),
    ["semantic.question.medical_bite.positive"] = phraseFamily(
        "MedicalBitePositive", "Yes, I've been bitten.",
        "Yes. I've been bitten, and I appreciate you checking.",
        "Yes. I've been bitten.", "Yes. I've been bitten. That's all."
    ),
    ["semantic.question.medical_bite.negative"] = phraseFamily(
        "MedicalBiteNegative", "No, I don't have a recorded bite.",
        "No, I don't have a recorded bite. Thanks for checking.",
        "No bite.", "No bite. Leave it there."
    ),
    ["semantic.question.medical_bite.unknown"] = phraseFamily(
        "MedicalBiteUnknown", "I can't confirm whether I've been bitten.",
        "I can't confirm it, but thanks for checking.", "Can't confirm.",
        "I can't confirm that. Don't press me."
    ),
    ["semantic.question.health_state.injured"] = phraseFamily(
        "HealthStateInjured", "I'm hurt, but I'm managing.",
        "I'm hurt, but I'm managing. Thanks for asking.", "I'm hurt.",
        "I'm hurt. Give me space."
    ),
    ["semantic.question.health_state.healthy"] = phraseFamily(
        "HealthStateHealthy", "I'm doing okay.",
        "I'm doing okay. Thanks for checking in.", "I'm okay.",
        "I'm fine. Don't make a thing of it."
    ),
    ["semantic.question.health_state.unknown"] = phraseFamily(
        "HealthStateUnknown", "I can't confirm my health status right now.",
        "I can't confirm it right now, but thanks for asking.", "Can't confirm.",
        "I can't confirm that."
    ),
}
