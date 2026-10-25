-- Wellbeing and medical response pools.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
Catalog.Register("semantic.question.wellbeing", {
    variants = {
        {
            id = "semantic.question.wellbeing.panic",
            templateID = "semantic.question.wellbeing.panic",
            fallback = "I'm pretty shaken up right now.",
            when = {
                emotionType = "panic",
                emotionUrgency = { "critical", "emergency" },
            },
            priority = 4,
        },
        {
            id = "semantic.question.wellbeing.stress",
            templateID = "semantic.question.wellbeing.stress",
            fallback = "I'm tense, but I can keep going.",
            when = {
                emotionType = "stress",
                emotionUrgency = { "critical", "emergency" },
            },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.thirst",
            templateID = "semantic.question.wellbeing.thirst",
            fallback = "I'm pretty thirsty. Could you spare some water?",
            when = { needType = "thirst", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.thirst_alt",
            templateID = "semantic.question.wellbeing.thirst_alt",
            fallback = "I could really use a drink. Do you have any water?",
            when = { needType = "thirst", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.hunger",
            templateID = "semantic.question.wellbeing.hunger",
            fallback = "I'm pretty hungry, if I'm honest. Do you have anything to eat?",
            when = { needType = "hunger", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.hunger_alt",
            templateID = "semantic.question.wellbeing.hunger_alt",
            fallback = "I'm getting hungry. Could you spare something to eat?",
            when = { needType = "hunger", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.fatigue",
            templateID = "semantic.question.wellbeing.fatigue",
            fallback = "I'm worn out, but I can still manage.",
            when = { needType = "fatigue", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.fatigue_alt",
            templateID = "semantic.question.wellbeing.fatigue_alt",
            fallback = "I'm tired. A little rest would help.",
            when = { needType = "fatigue", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.injured",
            templateID = "semantic.question.wellbeing.injured",
            fallback = "A little banged up, but I'll manage.",
            when = { healthState = { "injured", "wounded", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.default",
            templateID = "semantic.question.wellbeing.default",
            fallback = "I'm okay. How about you?",
        },
    },
})

Catalog.Register("semantic.question.medical_bite.positive", {
    variants = {
        {
            id = "semantic.question.medical_bite.positive.default",
            templateID = "semantic.question.medical_bite.positive",
            fallback = "Yes, I've been bitten.",
            dialogueAct = "MEDICAL_STATUS",
            topic = "MEDICAL",
            groundedFactRefs = { "npc.health.body.wounds" },
            uncertainty = "known",
            tone = "direct",
        },
    },
})

Catalog.Register("semantic.question.medical_bite.negative", {
    variants = {
        {
            id = "semantic.question.medical_bite.negative.default",
            templateID = "semantic.question.medical_bite.negative",
            fallback = "No, I don't have a recorded bite.",
            dialogueAct = "MEDICAL_STATUS",
            topic = "MEDICAL",
            groundedFactRefs = { "npc.health.body.wounds" },
            uncertainty = "known",
            tone = "direct",
        },
    },
})

Catalog.Register("semantic.question.medical_bite.unknown", {
    variants = {
        {
            id = "semantic.question.medical_bite.unknown.default",
            templateID = "semantic.question.medical_bite.unknown",
            fallback = "I can't confirm whether I've been bitten.",
            dialogueAct = "MEDICAL_STATUS",
            topic = "MEDICAL",
            uncertainty = "unknown",
            tone = "cautious",
        },
    },
})

-- Grounded wellbeing uses a separate bounded pool so the generated dataset
-- cannot crowd out the base question variants. The resolver enters this
-- pool only when the existing situation provider exposes a known injury and
-- an authored personality style.
local groundedRegistered, groundedReason = Catalog.Register(
    "semantic.question.wellbeing.grounded", {
    variants = {
        {
            id = "semantic.question.wellbeing.grounded.friendly",
            templateID = "semantic.question.wellbeing.grounded.friendly",
            fallback = "I took a bad hit, but I'm steady enough to keep moving. Thanks for checking in.",
            when = {
                healthState = { "injured", "wounded", "critical" },
                socialStyle = { "friendly", "protective" },
            },
            priority = 5,
            plan = {
                dialogueAct = "WELLBEING_REPORT",
                sourcePoolID = "semantic.question.wellbeing.grounded",
                topic = "WELLBEING",
                groundedFactRefs = { "npc.healthState" },
                uncertainty = "known",
                tone = "warm",
                personalityStyle = "friendly",
                turns = {
                    {
                        id = "grounded_fact",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.wellbeing.grounded.friendly.fact",
                                fallback = "I took a bad hit, but I'm steady enough to keep moving.",
                            },
                            {
                                kind = "translation",
                                templateID = "semantic.question.wellbeing.grounded.friendly.tone",
                                fallback = "Thanks for checking in.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.wellbeing.grounded.withdrawn",
            templateID = "semantic.question.wellbeing.grounded.withdrawn",
            fallback = "I'm hurt, but I'm managing. I'd rather not make a big thing of it.",
            when = {
                healthState = { "injured", "wounded", "critical" },
                socialStyle = "withdrawn",
            },
            priority = 5,
            plan = {
                dialogueAct = "WELLBEING_REPORT",
                sourcePoolID = "semantic.question.wellbeing.grounded",
                topic = "WELLBEING",
                groundedFactRefs = { "npc.healthState" },
                uncertainty = "known",
                tone = "guarded",
                personalityStyle = "withdrawn",
                turns = {
                    {
                        id = "grounded_fact",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.wellbeing.grounded.withdrawn.fact",
                                fallback = "I'm hurt, but I'm managing.",
                            },
                            {
                                kind = "translation",
                                templateID = "semantic.question.wellbeing.grounded.withdrawn.tone",
                                fallback = "I'd rather not make a big thing of it.",
                            },
                        },
                    },
                },
            },
        },
    },
})
if groundedRegistered ~= true then
    error("grounded wellbeing response pool unavailable ("
        .. tostring(groundedReason) .. ")")
end


return true
