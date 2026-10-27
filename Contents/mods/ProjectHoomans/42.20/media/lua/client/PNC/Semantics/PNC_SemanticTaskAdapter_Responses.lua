-- Default response pools for parameterized semantic task capabilities.
-- FETCH and WAIT_AT keep their specialized pools with their metadata; these
-- pools cover the shared item-action capability family.

local TASK_RESPONSE_POOLS = {
    GIVE = {
        admitted = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiveAdmitted",
            en = "Okay, I'll give that to you.",
            tl = "Sige, ibibigay ko iyon sa iyo.",
        },
        active = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiveActive",
            en = "I'm handing that over now.",
            tl = "Ibinibigay ko na iyon ngayon.",
        },
        completed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiveCompleted",
            en = "Here you go.",
            tl = "Heto na.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiveRejected",
            en = "I can't give that right now.",
            tl = "Hindi ko maibigay iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedGiveFailed",
            en = "I couldn't give that.",
            tl = "Hindi ko naibigay iyon.",
        },
    },
    EAT = {
        admitted = {
            key = "UI_PNC_Conversation_Semantic_GeneratedEatAdmitted",
            en = "I'll eat that.",
            tl = "Kakainin ko iyon.",
        },
        active = {
            key = "UI_PNC_Conversation_Semantic_GeneratedEatActive",
            en = "I'm eating that now.",
            tl = "Kinakain ko na iyon ngayon.",
        },
        completed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedEatCompleted",
            en = "That hit the spot.",
            tl = "Sakto iyon.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedEatRejected",
            en = "I can't eat that right now.",
            tl = "Hindi ko makain iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedEatFailed",
            en = "I couldn't eat that.",
            tl = "Hindi ko nakain iyon.",
        },
    },
    DRINK = {
        admitted = {
            key = "UI_PNC_Conversation_Semantic_GeneratedDrinkAdmitted",
            en = "I'll drink that.",
            tl = "Iinumin ko iyon.",
        },
        active = {
            key = "UI_PNC_Conversation_Semantic_GeneratedDrinkActive",
            en = "I'm drinking that now.",
            tl = "Ini-inom ko na iyon ngayon.",
        },
        completed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedDrinkCompleted",
            en = "I feel better.",
            tl = "Mas mabuti na ang pakiramdam ko.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedDrinkRejected",
            en = "I can't drink that right now.",
            tl = "Hindi ko mainom iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedDrinkFailed",
            en = "I couldn't drink that.",
            tl = "Hindi ko nainom iyon.",
        },
    },
    REFILL = {
        admitted = {
            key = "UI_PNC_Conversation_Semantic_GeneratedRefillAdmitted",
            en = "I'll refill that.",
            tl = "Pupunuin ko iyon.",
        },
        active = {
            key = "UI_PNC_Conversation_Semantic_GeneratedRefillActive",
            en = "I'm refilling that now.",
            tl = "Pinupuno ko na iyon ngayon.",
        },
        completed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedRefillCompleted",
            en = "It's full now.",
            tl = "Puno na ito ngayon.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedRefillRejected",
            en = "I can't refill that right now.",
            tl = "Hindi ko mapuno iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedRefillFailed",
            en = "I couldn't refill that.",
            tl = "Hindi ko napuno iyon.",
        },
    },
    CONSUME = {
        admitted = {
            key = "UI_PNC_Conversation_Semantic_GeneratedConsumeAdmitted",
            en = "I'll use that.",
            tl = "Gagamitin ko iyon.",
        },
        active = {
            key = "UI_PNC_Conversation_Semantic_GeneratedConsumeActive",
            en = "I'm using that now.",
            tl = "Ginagamit ko na iyon ngayon.",
        },
        completed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedConsumeCompleted",
            en = "That's done.",
            tl = "Tapos na iyon.",
        },
        rejected = {
            key = "UI_PNC_Conversation_Semantic_GeneratedConsumeRejected",
            en = "I can't use that right now.",
            tl = "Hindi ko magamit iyon ngayon.",
        },
        failed = {
            key = "UI_PNC_Conversation_Semantic_GeneratedConsumeFailed",
            en = "I couldn't use that.",
            tl = "Hindi ko nagamit iyon.",
        },
    },
}

return TASK_RESPONSE_POOLS

