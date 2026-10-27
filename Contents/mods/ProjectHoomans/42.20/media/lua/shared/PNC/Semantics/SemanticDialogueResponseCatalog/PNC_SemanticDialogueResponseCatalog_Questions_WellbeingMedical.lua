-- Wellbeing and medical response pools.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
Catalog.Register("semantic.question.wellbeing", {
    variants = {
        {
            id = "semantic.question.wellbeing.panic",
            templateID = "semantic.question.wellbeing.panic",

            when = {
                emotionType = "panic",
                emotionUrgency = { "critical", "emergency" },
            },
            priority = 4,
        },
        {
            id = "semantic.question.wellbeing.stress",
            templateID = "semantic.question.wellbeing.stress",

            when = {
                emotionType = "stress",
                emotionUrgency = { "critical", "emergency" },
            },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.thirst",
            templateID = "semantic.question.wellbeing.thirst",

            when = { needType = "thirst", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.thirst_alt",
            templateID = "semantic.question.wellbeing.thirst_alt",

            when = { needType = "thirst", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 3,
        },
        {
            id = "semantic.question.wellbeing.hunger",
            templateID = "semantic.question.wellbeing.hunger",

            when = { needType = "hunger", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.hunger_alt",
            templateID = "semantic.question.wellbeing.hunger_alt",

            when = { needType = "hunger", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.fatigue",
            templateID = "semantic.question.wellbeing.fatigue",

            when = { needType = "fatigue", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.fatigue_alt",
            templateID = "semantic.question.wellbeing.fatigue_alt",

            when = { needType = "fatigue", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.injured",
            templateID = "semantic.question.wellbeing.injured",

            when = { healthState = { "injured", "wounded", "critical" } },
            priority = 2,
        },
        {
            id = "semantic.question.wellbeing.default",
            templateID = "semantic.question.wellbeing.default",

        },
    },
})

Catalog.Register("semantic.question.medical_bite.positive", {
    variants = {
        {
            id = "semantic.question.medical_bite.positive.default",
            templateID = "semantic.question.medical_bite.positive",

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

                            },
                            {
                                kind = "translation",
                                templateID = "semantic.question.wellbeing.grounded.friendly.tone",

                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.wellbeing.grounded.withdrawn",
            templateID = "semantic.question.wellbeing.grounded.withdrawn",

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

                            },
                            {
                                kind = "translation",
                                templateID = "semantic.question.wellbeing.grounded.withdrawn.tone",

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
