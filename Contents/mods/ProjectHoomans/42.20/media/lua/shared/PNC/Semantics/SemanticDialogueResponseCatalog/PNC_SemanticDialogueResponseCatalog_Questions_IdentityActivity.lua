-- Identity, activity, and conversational-topic response pools.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
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

Catalog.Register("semantic.question.whats_up", {
    variants = {
        {
            id = "semantic.question.whats_up.weather",
            templateID = "semantic.question.whats_up.weather",
            fallback = "The weather is the main thing on my mind right now.",
            when = {
                subject = "CONVERSATION_TOPIC",
                raining = true,
            },
            priority = 2,
        },
        {
            id = "semantic.question.whats_up.traveling",
            templateID = "semantic.question.whats_up.traveling",
            fallback = "I'm keeping moving and watching what is ahead.",
            when = {
                subject = "CONVERSATION_TOPIC",
                activity = "traveling",
            },
            priority = 2,
        },
        {
            id = "semantic.question.whats_up.busy",
            templateID = "semantic.question.whats_up.busy",
            fallback = "I'm keeping busy and trying to stay useful.",
            when = {
                subject = "CONVERSATION_TOPIC",
                busy = true,
            },
            priority = 2,
        },
        {
            id = "semantic.question.whats_up.default",
            templateID = "semantic.question.whats_up.default",
            fallback = "Not much. I'm just trying to keep things together.",
            when = { subject = "CONVERSATION_TOPIC" },
        },
        {
            id = "semantic.question.whats_up.default_alt",
            templateID = "semantic.question.whats_up.default_alt",
            fallback = "Same as ever. Staying alive and watching the road.",
            when = { subject = "CONVERSATION_TOPIC" },
        },
    },
})


return true
