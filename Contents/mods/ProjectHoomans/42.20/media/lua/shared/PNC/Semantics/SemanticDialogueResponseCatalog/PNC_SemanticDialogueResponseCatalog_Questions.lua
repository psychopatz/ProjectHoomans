-- Authored deterministic response pools for the semantic dialogue catalog.
-- This module owns response content; selection and validation stay in the
-- catalog entry so all callers share one bounded contract.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

Catalog.Register("semantic.question.identity", {
    variants = {
        {
            id = "semantic.question.identity.default",
            templateID = "semantic.question.identity",
            fallback = "I'll tell you my name once we've established some trust. What's your name?",
        },
        {
            id = "semantic.question.identity.untrustworthy",
            templateID = "semantic.question.identity",
            fallback = "I don't share my name with liars. What's yours, truthfully?",
            when = { identityTrust = "untrustworthy" },
            priority = 2,
        },
    },
})

Catalog.Register("semantic.question.activity", {
    variants = {
        {
            id = "semantic.question.activity.combat",
            templateID = "semantic.question.activity.combat",
            fallback = "I'm keeping an eye on things.",
            when = { activity = "combat" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.fishing",
            templateID = "semantic.question.activity.fishing",
            fallback = "I'm trying to catch something.",
            when = { activity = "fishing" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.working",
            templateID = "semantic.question.activity.working",
            fallback = "I'm working on something.",
            when = { activity = "working" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.traveling",
            templateID = "semantic.question.activity.traveling",
            fallback = "I'm on the move.",
            when = { activity = "traveling" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.resting",
            templateID = "semantic.question.activity.resting",
            fallback = "I'm taking a breather.",
            when = { activity = "resting" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.default",
            templateID = "semantic.question.activity.default",
            fallback = "Not much. Just getting by.",
        },
    },
})

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

Catalog.Register("semantic.question.needs.offer", {
    variants = {
        {
            id = "semantic.question.needs.offer.hunger",
            templateID = "semantic.question.needs.offer.hunger",
            fallback = "Food would help, but I don't have an exact amount yet.",
            when = {
                needType = "hunger",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
            plan = {
                dialogueAct = "NEEDS_REPORT",
                sourcePoolID = "semantic.question.needs.offer",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.hunger" },
                uncertainty = "known",
                tone = "direct",
                turns = {
                    {
                        id = "needs_report",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.offer.hunger",
                                fallback = "Food would help, but I don't have an exact amount yet.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.offer.thirst",
            templateID = "semantic.question.needs.offer.thirst",
            fallback = "Water would help, but I don't have an exact amount yet.",
            when = {
                needType = "thirst",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
            plan = {
                dialogueAct = "NEEDS_REPORT",
                sourcePoolID = "semantic.question.needs.offer",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.thirst" },
                uncertainty = "known",
                tone = "direct",
                turns = {
                    {
                        id = "needs_report",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.offer.thirst",
                                fallback = "Water would help, but I don't have an exact amount yet.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.offer.fatigue",
            templateID = "semantic.question.needs.offer.fatigue",
            fallback = "A little rest would help, but this isn't something I can count.",
            when = {
                needType = "fatigue",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 2,
            plan = {
                dialogueAct = "NEEDS_REPORT",
                sourcePoolID = "semantic.question.needs.offer",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.fatigue" },
                uncertainty = "known",
                tone = "direct",
                turns = {
                    {
                        id = "needs_report",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.offer.fatigue",
                                fallback = "A little rest would help, but this isn't something I can count.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.offer.unknown",
            templateID = "semantic.question.needs.offer.unknown",
            fallback = "I don't know what I need right now.",
            priority = 0,
            plan = {
                dialogueAct = "NEEDS_REPORT",
                sourcePoolID = "semantic.question.needs.offer",
                topic = "NEEDS",
                uncertainty = "unknown",
                tone = "uncertain",
                turns = {
                    {
                        id = "needs_report",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.offer.unknown",
                                fallback = "I don't know what I need right now.",
                            },
                        },
                    },
                },
            },
        },
    },
})

Catalog.Register("semantic.question.needs.quantity", {
    variants = {
        {
            id = "semantic.question.needs.quantity.hunger",
            templateID = "semantic.question.needs.quantity.hunger",
            fallback = "I know food is what I need, but I can't give you an exact amount yet.",
            when = {
                needType = "hunger",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
            plan = {
                dialogueAct = "NEEDS_QUANTITY",
                sourcePoolID = "semantic.question.needs.quantity",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.hunger" },
                uncertainty = "pending",
                tone = "direct",
                turns = {
                    {
                        id = "needs_quantity",
                        continuation = "end",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.quantity.hunger",
                                fallback = "I know food is what I need, but I can't give you an exact amount yet.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.quantity.thirst",
            templateID = "semantic.question.needs.quantity.thirst",
            fallback = "I know water is what I need, but I can't give you an exact amount yet.",
            when = {
                needType = "thirst",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
            plan = {
                dialogueAct = "NEEDS_QUANTITY",
                sourcePoolID = "semantic.question.needs.quantity",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.thirst" },
                uncertainty = "pending",
                tone = "direct",
                turns = {
                    {
                        id = "needs_quantity",
                        continuation = "end",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.quantity.thirst",
                                fallback = "I know water is what I need, but I can't give you an exact amount yet.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.quantity.unknown",
            templateID = "semantic.question.needs.quantity.unknown",
            fallback = "I can't confirm an exact amount yet. Which item do you mean?",
            priority = 0,
            plan = {
                dialogueAct = "ASK_CLARIFICATION",
                sourcePoolID = "semantic.question.needs.quantity",
                topic = "NEEDS",
                groundedFactRefs = {},
                uncertainty = "ambiguous",
                tone = "clarifying",
                turns = {
                    {
                        id = "needs_quantity_clarification",
                        continuation = "end",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.quantity.unknown",
                                fallback = "I can't confirm an exact amount yet. Which item do you mean?",
                            },
                        },
                    },
                },
            },
        },
    },
})

Catalog.Register("semantic.question.needs.proposal", {
    variants = {
        {
            id = "semantic.question.needs.proposal.hunger",
            templateID = "semantic.question.needs.proposal.hunger",
            fallback = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
            when = {
                needType = "hunger",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
            plan = {
                dialogueAct = "PROMISE_ACKNOWLEDGEMENT",
                sourcePoolID = "semantic.question.needs.proposal",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.hunger" },
                uncertainty = "pending",
                tone = "direct",
                turns = {
                    {
                        id = "proposal_acknowledged",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.proposal.hunger",
                                fallback = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.proposal.thirst",
            templateID = "semantic.question.needs.proposal.thirst",
            fallback = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
            when = {
                needType = "thirst",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 3,
            plan = {
                dialogueAct = "PROMISE_ACKNOWLEDGEMENT",
                sourcePoolID = "semantic.question.needs.proposal",
                topic = "NEEDS",
                groundedFactRefs = { "npc.needs.thirst" },
                uncertainty = "pending",
                tone = "direct",
                turns = {
                    {
                        id = "proposal_acknowledged",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.proposal.thirst",
                                fallback = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                            },
                        },
                    },
                },
            },
        },
        {
            id = "semantic.question.needs.proposal.unknown",
            templateID = "semantic.question.needs.proposal.unknown",
            fallback = "I can keep that as a proposal, but I need to confirm the item and amount before I record a commitment.",
            priority = 0,
            plan = {
                dialogueAct = "PROMISE_ACKNOWLEDGEMENT",
                sourcePoolID = "semantic.question.needs.proposal",
                topic = "NEEDS",
                groundedFactRefs = {},
                uncertainty = "pending",
                tone = "clarifying",
                turns = {
                    {
                        id = "proposal_acknowledged",
                        continuation = "continue",
                        segments = {
                            {
                                kind = "translation",
                                templateID = "semantic.question.needs.proposal.unknown",
                                fallback = "I can keep that as a proposal, but I need to confirm the item and amount before I record a commitment.",
                            },
                        },
                    },
                },
            },
        },
    },
})

-- Keep an unsupported wellbeing snapshot out of the normal response pool.
-- That pool already includes the bounded generated response variants; this
-- separate pool makes uncertainty explicit without expanding its limit.
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

return true
