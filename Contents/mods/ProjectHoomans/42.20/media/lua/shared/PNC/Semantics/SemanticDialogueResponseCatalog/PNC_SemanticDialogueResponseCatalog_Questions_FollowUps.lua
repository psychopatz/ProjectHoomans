-- Wellbeing follow-ups, self-state, and relationship response pools.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
Catalog.Register("semantic.question.wellbeing.unknown", {
    variants = {
        {
            id = "semantic.question.wellbeing.unknown",
            templateID = "semantic.question.wellbeing.unknown",
            fallback = "I'm not sure how I'm doing right now.",
        },
    },
})

Catalog.Register("semantic.question.wellbeing.follow_up", {
    variants = {
        {
            id = "semantic.question.wellbeing.follow_up.panic",
            templateID = "semantic.question.wellbeing.follow_up.panic",
            fallback = "I'm still pretty shaken up.",
            when = {
                emotionType = "panic",
                emotionUrgency = { "critical", "emergency" },
            },
            priority = 4,
        },
        {
            id = "semantic.question.wellbeing.follow_up.stress",
            templateID = "semantic.question.wellbeing.follow_up.stress",
            fallback = "I'm still tense and having trouble settling down.",
            when = {
                emotionType = "stress",
                emotionUrgency = { "critical", "emergency" },
            },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.follow_up.thirst",
            templateID = "semantic.question.wellbeing.follow_up.thirst",
            fallback = "I'm still pretty thirsty.",
            when = {
                needType = "thirst",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.follow_up.hunger",
            templateID = "semantic.question.wellbeing.follow_up.hunger",
            fallback = "I'm still hungry.",
            when = {
                needType = "hunger",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.follow_up.fatigue",
            templateID = "semantic.question.wellbeing.follow_up.fatigue",
            fallback = "I'm still worn out.",
            when = {
                needType = "fatigue",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.follow_up.injured",
            templateID = "semantic.question.wellbeing.follow_up.injured",
            fallback = "I took a bad hit. It's still bothering me.",
            when = { healthState = { "injured", "wounded", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.follow_up.unknown",
            templateID = "semantic.question.wellbeing.follow_up.unknown",
            fallback = "I don't have enough detail to say what's wrong yet.",
            when = { healthState = "unknown" },
            priority = 1,
        },
        {
            id = "semantic.question.wellbeing.follow_up.default",
            templateID = "semantic.question.wellbeing.follow_up.default",
            fallback = "I don't have enough detail to say what's wrong yet.",
        },
    },
})

Catalog.Register("semantic.self_state", {
    variants = {
        {
            id = "semantic.self_state.wellbeing",
            templateID = "semantic.self_state.wellbeing",
            fallback = "I'm glad to hear it. Thanks for checking in.",
            when = { subject = "WELLBEING" },
            priority = 2,
        },
        {
            id = "semantic.self_state.wellbeing_alt",
            templateID = "semantic.self_state.wellbeing_alt",
            fallback = "That's good to hear. I appreciate you asking.",
            when = { subject = "WELLBEING" },
            priority = 2,
        },
        {
            id = "semantic.self_state.hunger",
            templateID = "semantic.self_state.hunger",
            fallback = "Sorry to hear that. I hope we find something to eat soon.",
            when = { subject = "HUNGER" },
            priority = 2,
        },
        {
            id = "semantic.self_state.hunger_alt",
            templateID = "semantic.self_state.hunger_alt",
            fallback = "That sounds rough. Let's keep an eye out for food.",
            when = { subject = "HUNGER" },
            priority = 2,
        },
        {
            id = "semantic.self_state.thirst",
            templateID = "semantic.self_state.thirst",
            fallback = "I hope we can find some water for you soon.",
            when = { subject = "THIRST" },
            priority = 2,
        },
        {
            id = "semantic.self_state.thirst_alt",
            templateID = "semantic.self_state.thirst_alt",
            fallback = "That's rough. Let's look for something to drink.",
            when = { subject = "THIRST" },
            priority = 2,
        },
        {
            id = "semantic.self_state.fatigue",
            templateID = "semantic.self_state.fatigue",
            fallback = "I hear you. I hope you get a chance to rest soon.",
            when = { subject = "FATIGUE" },
            priority = 2,
        },
        {
            id = "semantic.self_state.fatigue_alt",
            templateID = "semantic.self_state.fatigue_alt",
            fallback = "This is wearing. Take a breather when you can.",
            when = { subject = "FATIGUE" },
            priority = 2,
        },
    },
})

Catalog.Register("semantic.question.relationship_status.committed", {
    variants = {
        {
            id = "semantic.question.relationship_status.committed",
            templateID = "semantic.question.relationship_status.committed",
            fallback = "I thought we were already together.",
        },
    },
})

Catalog.Register("semantic.question.relationship_status.unknown", {
    variants = {
        {
            id = "semantic.question.relationship_status.uncertain",
            templateID = "semantic.question.relationship_status.uncertain",
            fallback = "I haven't really thought about dating. Right now, I'm focused on surviving.",
        },
        {
            id = "semantic.question.relationship_status.uncertain_alt",
            templateID = "semantic.question.relationship_status.uncertain_alt",
            fallback = "Honestly, I haven't had much room to think about relationships lately.",
        },
        {
            id = "semantic.question.relationship_status.withdrawn",
            templateID = "semantic.question.relationship_status.withdrawn",
            fallback = "I'd rather not get into that. There's too much going on right now.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
    },
})

Catalog.Register(
    "semantic.question.relationship_status.committed_after_compliment",
    {
        variants = {
            {
                id = "semantic.question.relationship_status.after_compliment.committed",
                templateID = "semantic.question.relationship_status.after_compliment.committed",
                fallback = "Thanks for the compliment, but I thought we were already together.",
            },
        },
    }
)

Catalog.Register(
    "semantic.question.relationship_status.unknown_after_compliment",
    {
        variants = {
            {
                id = "semantic.question.relationship_status.after_compliment.unknown",
                templateID = "semantic.question.relationship_status.after_compliment.unknown",
                fallback = "That's kind of you to ask. I don't have a clear answer right now.",
            },
            {
                id = "semantic.question.relationship_status.after_compliment.unknown_alt",
                templateID = "semantic.question.relationship_status.after_compliment.unknown_alt",
                fallback = "Thanks for saying that. I can't give you a clear answer about relationships right now.",
            },
            {
                id = "semantic.question.relationship_status.after_compliment.withdrawn",
                templateID = "semantic.question.relationship_status.after_compliment.withdrawn",
                fallback = "Thanks, but I'd rather keep that personal.",
                when = { socialStyle = "withdrawn" },
                priority = 2,
            },
        },
    }
)

Catalog.Register(
    "semantic.question.relationship_status.acknowledged",
    {
        variants = {
            {
                id = "semantic.question.relationship_status.acknowledged.default",
                templateID = "semantic.question.relationship_status.acknowledged.default",
                fallback = "Thanks for understanding. It's hard to think about relationships with everything going on.",
            },
            {
                id = "semantic.question.relationship_status.acknowledged.alternate",
                templateID = "semantic.question.relationship_status.acknowledged.alternate",
                fallback = "I appreciate you listening. It's hard to make plans while we're trying to survive.",
            },
            {
                id = "semantic.question.relationship_status.acknowledged.withdrawn",
                templateID = "semantic.question.relationship_status.acknowledged.withdrawn",
                fallback = "Thanks. I'd rather leave it there for now.",
                when = { socialStyle = "withdrawn" },
                priority = 2,
            },
        },
    }
)

-- Event follow-up answers are selected by semantic question kind.  The
-- bounded fact value is supplied only after this meaning is selected; it is
-- never recovered from rendered NPC speech.
local EVENT_FOLLOW_UPS = {
    what_happened = "I don't have a confirmed account of what happened.",
    location = "I don't have a confirmed location.",
    quantity = "I don't have a confirmed count.",
    attacker = "I don't have a confirmed account of who did it.",
    need = "I don't have a confirmed need to report.",
    deceased = "I don't have a confirmed name for who died.",
    next = "I don't have a confirmed next step.",
    health = "I don't have a confirmed health update.",
    pursuer = "I don't have a confirmed account of who was after them.",
    what = "I don't have a confirmed description of it.",
}

for questionKind, fallback in pairs(EVENT_FOLLOW_UPS) do
    local poolID = "semantic.question.event_follow_up." .. questionKind
    Catalog.Register(poolID, {
        variants = {
            {
                id = poolID .. ".answer",
                templateID = poolID .. ".answer",
                fallback = "%1",
                plan = {
                    dialogueAct = "FACT_ANSWER",
                    sourcePoolID = poolID,
                    topic = "EVENT_FOLLOW_UP",
                    turns = { { segments = {
                        { kind = "literal", text = "%1" },
                    } } },
                },
            },
        },
    })
    -- Keep the unknown wording in the semantic pool's fallback contract for
    -- runtimes that do not provide a fact argument.
    if fallback == "" then return false end
end


return true
