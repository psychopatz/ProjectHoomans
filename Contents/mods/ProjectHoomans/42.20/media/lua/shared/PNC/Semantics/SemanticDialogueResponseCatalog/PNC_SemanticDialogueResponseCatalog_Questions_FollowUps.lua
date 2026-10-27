-- Wellbeing follow-ups, self-state, and relationship response pools.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
Catalog.Register("semantic.question.wellbeing.unknown", {
    variants = {
        {
            id = "semantic.question.wellbeing.unknown",
            templateID = "semantic.question.wellbeing.unknown",

        },
    },
})

Catalog.Register("semantic.question.wellbeing.follow_up", {
    variants = {
        {
            id = "semantic.question.wellbeing.follow_up.panic",
            templateID = "semantic.question.wellbeing.follow_up.panic",

            when = {
                emotionType = "panic",
                emotionUrgency = { "critical", "emergency" },
            },
            priority = 4,
        },
        {
            id = "semantic.question.wellbeing.follow_up.stress",
            templateID = "semantic.question.wellbeing.follow_up.stress",

            when = {
                emotionType = "stress",
                emotionUrgency = { "critical", "emergency" },
            },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.follow_up.thirst",
            templateID = "semantic.question.wellbeing.follow_up.thirst",

            when = {
                needType = "thirst",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.follow_up.hunger",
            templateID = "semantic.question.wellbeing.follow_up.hunger",

            when = {
                needType = "hunger",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.follow_up.fatigue",
            templateID = "semantic.question.wellbeing.follow_up.fatigue",

            when = {
                needType = "fatigue",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.follow_up.injured",
            templateID = "semantic.question.wellbeing.follow_up.injured",

            when = { healthState = { "injured", "wounded", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.follow_up.unknown",
            templateID = "semantic.question.wellbeing.follow_up.unknown",

            when = { healthState = "unknown" },
            priority = 1,
        },
        {
            id = "semantic.question.wellbeing.follow_up.default",
            templateID = "semantic.question.wellbeing.follow_up.default",

        },
    },
})

Catalog.Register("semantic.self_state", {
    variants = {
        {
            id = "semantic.self_state.wellbeing",
            templateID = "semantic.self_state.wellbeing",

            when = { subject = "WELLBEING" },
            priority = 2,
        },
        {
            id = "semantic.self_state.wellbeing_alt",
            templateID = "semantic.self_state.wellbeing_alt",

            when = { subject = "WELLBEING" },
            priority = 2,
        },
        {
            id = "semantic.self_state.hunger",
            templateID = "semantic.self_state.hunger",

            when = { subject = "HUNGER" },
            priority = 2,
        },
        {
            id = "semantic.self_state.hunger_alt",
            templateID = "semantic.self_state.hunger_alt",

            when = { subject = "HUNGER" },
            priority = 2,
        },
        {
            id = "semantic.self_state.thirst",
            templateID = "semantic.self_state.thirst",

            when = { subject = "THIRST" },
            priority = 2,
        },
        {
            id = "semantic.self_state.thirst_alt",
            templateID = "semantic.self_state.thirst_alt",

            when = { subject = "THIRST" },
            priority = 2,
        },
        {
            id = "semantic.self_state.fatigue",
            templateID = "semantic.self_state.fatigue",

            when = { subject = "FATIGUE" },
            priority = 2,
        },
        {
            id = "semantic.self_state.fatigue_alt",
            templateID = "semantic.self_state.fatigue_alt",

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

        },
    },
})

Catalog.Register("semantic.question.relationship_status.unknown", {
    variants = {
        {
            id = "semantic.question.relationship_status.uncertain",
            templateID = "semantic.question.relationship_status.uncertain",

        },
        {
            id = "semantic.question.relationship_status.uncertain_alt",
            templateID = "semantic.question.relationship_status.uncertain_alt",

        },
        {
            id = "semantic.question.relationship_status.withdrawn",
            templateID = "semantic.question.relationship_status.withdrawn",

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

            },
            {
                id = "semantic.question.relationship_status.after_compliment.unknown_alt",
                templateID = "semantic.question.relationship_status.after_compliment.unknown_alt",

            },
            {
                id = "semantic.question.relationship_status.after_compliment.withdrawn",
                templateID = "semantic.question.relationship_status.after_compliment.withdrawn",

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

            },
            {
                id = "semantic.question.relationship_status.acknowledged.alternate",
                templateID = "semantic.question.relationship_status.acknowledged.alternate",

            },
            {
                id = "semantic.question.relationship_status.acknowledged.withdrawn",
                templateID = "semantic.question.relationship_status.acknowledged.withdrawn",

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
    what_happened = true,
    location = true,
    quantity = true,
    attacker = true,
    need = true,
    deceased = true,
    next = true,
    health = true,
    pursuer = true,
    what = true,
}

for questionKind in pairs(EVENT_FOLLOW_UPS) do
    local poolID = "semantic.question.event_follow_up." .. questionKind
    Catalog.Register(poolID, {
        variants = {
            {
                id = poolID .. ".answer",
                templateID = poolID,
                plan = {
                    dialogueAct = "FACT_ANSWER",
                    sourcePoolID = poolID,
                    topic = "EVENT_FOLLOW_UP",
                    turns = { { segments = {
                        { kind = "translation", templateID = poolID },
                    } } },
                },
            },
        },
    })
    local unknownPoolID = poolID .. ".unknown"
    Catalog.Register(unknownPoolID, {
        variants = {
            {
                id = unknownPoolID,
                templateID = unknownPoolID,
            },
        },
    })
end


return true
