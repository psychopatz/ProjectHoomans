-- Authored deterministic response pools for the semantic dialogue catalog.
-- This module owns response content; selection and validation stay in the
-- catalog entry so all callers share one bounded contract.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

Catalog.Register("semantic.greeting", {
    variants = {
        {
            id = "semantic.greeting.default",
            templateID = "semantic.greet.acknowledged",

        },
        {
            id = "semantic.greeting.dawn",
            templateID = "semantic.greet.morning",

            when = { timeBand = "dawn" },
            priority = 1,
        },
        {
            id = "semantic.greeting.rain",
            templateID = "semantic.greet.rain",

            when = { raining = true },
            priority = 1,
        },
        {
            id = "semantic.greeting.fog",
            templateID = "semantic.greet.fog",

            when = { foggy = true },
            priority = 1,
        },
        {
            id = "semantic.greeting.busy",
            templateID = "semantic.greet.busy",

            when = { busy = true },
            priority = 0,
        },
        {
            id = "semantic.greeting.thirsty",
            templateID = "semantic.greet.thirsty",

            when = { needType = "thirst", needUrgency = { "moderate", "severe", "emergency", "critical" } },
            -- Weather and first-meet context remain the stronger opening
            -- signal; need pressure can still shape a neutral greeting.
            priority = 0,
        },
        {
            id = "semantic.greeting.first_meet",
            templateID = "semantic.greet.first_meet",

            when = { relationshipState = "FirstMeet" },
            priority = 1,
        },
        {
            id = "semantic.greeting.friendly",
            templateID = "semantic.greet.friendly",

            when = { socialStyle = "friendly" },
            priority = 0,
        },
        {
            id = "semantic.greeting.withdrawn",
            templateID = "semantic.greet.withdrawn",

            when = { socialStyle = "withdrawn" },
            priority = 0,
        },
    },
})

Catalog.Register("semantic.offer", {
    variants = {
        {
            id = "semantic.offer.stressed",
            templateID = "semantic.social.offer_stressed",

            when = {
                emotionType = { "stress", "panic" },
                emotionUrgency = {
                    "moderate", "severe", "critical", "emergency",
                },
            },
            priority = 4,
        },
        {
            id = "semantic.offer.hungry",
            templateID = "semantic.offer.interested",

            when = {
                needType = "hunger",
                needUrgency = { "moderate", "severe", "emergency", "critical" },
            },
            priority = 2,
        },
        {
            id = "semantic.offer.friendly",
            templateID = "semantic.social.offer_friendly",

            when = { socialStyle = { "friendly", "protective" } },
            priority = 1,
        },
        {
            id = "semantic.offer.trusted",
            templateID = "semantic.social.offer_trusted",

            when = {
                relationshipState = {
                    "Friend", "Trusted", "Ally", "Member", "Lover",
                },
            },
            priority = 1,
        },
        {
            id = "semantic.offer.withdrawn",
            templateID = "semantic.social.offer_withdrawn",

            when = { socialStyle = "withdrawn" },
            priority = 1,
        },
        {
            id = "semantic.offer.default",
            templateID = "semantic.offer.declined",

        },
    },
})

return true
