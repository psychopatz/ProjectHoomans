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

