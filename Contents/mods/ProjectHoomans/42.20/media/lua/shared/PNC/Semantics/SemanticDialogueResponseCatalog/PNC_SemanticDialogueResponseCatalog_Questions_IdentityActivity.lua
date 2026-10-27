-- Identity, activity, and conversational-topic response pools.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
Catalog.Register("semantic.question.identity", {
    variants = {
        {
            id = "semantic.question.identity.default",
            templateID = "semantic.question.identity",

        },
        {
            id = "semantic.question.identity.untrustworthy",
            templateID = "semantic.question.identity",

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

            when = { activity = "combat" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.fishing",
            templateID = "semantic.question.activity.fishing",

            when = { activity = "fishing" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.working",
            templateID = "semantic.question.activity.working",

            when = { activity = "working" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.traveling",
            templateID = "semantic.question.activity.traveling",

            when = { activity = "traveling" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.resting",
            templateID = "semantic.question.activity.resting",

            when = { activity = "resting" },
            priority = 2,
        },
        {
            id = "semantic.question.activity.default",
            templateID = "semantic.question.activity.default",

        },
    },
})

Catalog.Register("semantic.question.whats_up", {
    variants = {
        {
            id = "semantic.question.whats_up.weather",
            templateID = "semantic.question.whats_up.weather",

            when = {
                subject = "CONVERSATION_TOPIC",
                raining = true,
            },
            priority = 2,
        },
        {
            id = "semantic.question.whats_up.traveling",
            templateID = "semantic.question.whats_up.traveling",

            when = {
                subject = "CONVERSATION_TOPIC",
                activity = "traveling",
            },
            priority = 2,
        },
        {
            id = "semantic.question.whats_up.busy",
            templateID = "semantic.question.whats_up.busy",

            when = {
                subject = "CONVERSATION_TOPIC",
                busy = true,
            },
            priority = 2,
        },
        {
            id = "semantic.question.whats_up.default",
            templateID = "semantic.question.whats_up.default",

            when = { subject = "CONVERSATION_TOPIC" },
        },
        {
            id = "semantic.question.whats_up.default_alt",
            templateID = "semantic.question.whats_up.default_alt",

            when = { subject = "CONVERSATION_TOPIC" },
        },
    },
})


return true
