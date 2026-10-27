PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

Catalog.Register("semantic.thanks", {
    variants = {
        {
            id = "semantic.thanks.default",
            templateID = "semantic.social.thanks_response",

        },
    },
})

Catalog.Register("semantic.apology", {
    variants = {
        {
            id = "semantic.apology.stressed",
            templateID = "semantic.social.apology.stressed",

            when = {
                emotionType = { "stress", "panic" },
                emotionUrgency = {
                    "moderate", "severe", "critical", "emergency",
                },
            },
            priority = 4,
        },
        {
            id = "semantic.apology.friendly",
            templateID = "semantic.social.apology.friendly",

            when = { socialStyle = { "friendly", "protective" } },
            priority = 3,
        },
        {
            id = "semantic.apology.trusted",
            templateID = "semantic.social.apology.trusted",

            when = {
                relationshipState = {
                    "Friend", "Trusted", "Ally", "Member", "Lover",
                },
            },
            priority = 2,
        },
        {
            id = "semantic.apology.withdrawn",
            templateID = "semantic.social.apology.withdrawn",

            when = { socialStyle = "withdrawn" },
            priority = 1,
        },
        {
            id = "semantic.apology.default",
            templateID = "semantic.social.apology.default",

        },
    },
})

Catalog.Register("semantic.compliment", {
    variants = {
        {
            id = "semantic.compliment.default",
            templateID = "semantic.social.compliment.default",

        },
        {
            id = "semantic.compliment.alternate",
            templateID = "semantic.social.compliment.alternate",

        },
        {
            id = "semantic.compliment.friendly",
            templateID = "semantic.social.compliment.friendly",

            when = { socialStyle = { "friendly", "protective" } },
            priority = 3,
        },
        {
            id = "semantic.compliment.trusted",
            templateID = "semantic.social.compliment.trusted",

            when = { relationshipState = { "Member", "Lover" } },
            priority = 2,
        },
        {
            id = "semantic.compliment.withdrawn",
            templateID = "semantic.social.compliment.withdrawn",

            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
    },
})

Catalog.Register("semantic.accept", {
    variants = {
        {
            id = "semantic.accept.request",
            templateID = "semantic.social.accept_request",

            when = { hasPendingRequest = true },
            priority = 1,
        },
        {
            id = "semantic.accept.default",
            templateID = "semantic.social.acknowledged",

        },
    },
})

Catalog.Register("semantic.conversation.acknowledged", {
    variants = {
        {
            id = "semantic.conversation.acknowledged.friendly",
            templateID = "semantic.conversation.acknowledged.friendly",

            when = { socialStyle = { "friendly", "protective" } },
            priority = 2,
        },
        {
            id = "semantic.conversation.acknowledged.withdrawn",
            templateID = "semantic.conversation.acknowledged.withdrawn",

            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.conversation.acknowledged.default",
            templateID = "semantic.conversation.acknowledged.default",

        },
    },
})

Catalog.Register("semantic.refuse", {
    variants = {
        {
            id = "semantic.refuse.stressed",
            templateID = "semantic.social.dispute_stressed",

            when = {
                emotionType = { "stress", "panic" },
                emotionUrgency = {
                    "moderate", "severe", "critical", "emergency",
                },
            },
            priority = 4,
        },
        {
            id = "semantic.refuse.request",
            templateID = "semantic.social.refuse_request",

            when = { hasPendingRequest = true },
            priority = 5,
        },
        {
            id = "semantic.refuse.friendly",
            templateID = "semantic.social.dispute_friendly",

            when = { socialStyle = { "friendly", "protective" } },
            priority = 2,
        },
        {
            id = "semantic.refuse.trusted",
            templateID = "semantic.social.dispute_trusted",

            when = {
                relationshipState = {
                    "Friend", "Trusted", "Ally", "Member", "Lover",
                },
            },
            priority = 1,
        },
        {
            id = "semantic.refuse.withdrawn",
            templateID = "semantic.social.dispute_withdrawn",

            when = { socialStyle = "withdrawn" },
            priority = 1,
        },
        {
            id = "semantic.refuse.default",
            templateID = "semantic.social.refuse_default",

        },
    },
})

Catalog.Register("semantic.gossip", {
    variants = {
        {
            id = "semantic.gossip.memory",
            templateID = "semantic.gossip.memory",

            when = { memoryAvailable = true },
            priority = 2,
        },
        {
            id = "semantic.gossip.unknown",
            templateID = "semantic.gossip.unknown",

        },
    },
})

Catalog.Register("semantic.self_reflection", {
    variants = {
        {
            id = "semantic.self_reflection.friendly",
            templateID = "semantic.social.self_reflection.friendly",

            when = { socialStyle = { "friendly", "protective" } },
            priority = 4,
        },
        {
            id = "semantic.self_reflection.trusted",
            templateID = "semantic.social.self_reflection.trusted",

            -- Conversation authority currently projects Member/Lover as the
            -- established relationship categories. Keep the older labels as
            -- compatibility aliases for other context providers.
            when = {
                relationshipState = {
                    "Friend", "Trusted", "Ally", "Member", "Lover",
                },
            },
            priority = 3,
        },
        {
            id = "semantic.self_reflection.withdrawn",
            templateID = "semantic.social.self_reflection.withdrawn",

            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.self_reflection.stressed",
            templateID = "semantic.social.self_reflection.stressed",

            when = { emotionType = { "stress", "panic" } },
            priority = 1,
        },
        {
            id = "semantic.self_reflection.default",
            templateID = "semantic.social.self_reflection.default",

        },
    },
})

Catalog.Register("semantic.identity.evasion", {
    variants = {
        {
            id = "semantic.identity.evasion.untrustworthy",
            templateID = "semantic.identity.evasion.untrustworthy",

            when = { identityTrust = "untrustworthy" },
            priority = 5,
        },
        {
            id = "semantic.identity.evasion.friendly",
            templateID = "semantic.identity.evasion.friendly",

            when = { socialStyle = { "friendly", "protective" } },
            priority = 3,
        },
        {
            id = "semantic.identity.evasion.withdrawn",
            templateID = "semantic.identity.evasion.withdrawn",

            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.identity.evasion.default",
            templateID = "semantic.identity.evasion.default",

        },
    },
})


return true
