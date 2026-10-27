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
            fallback = "You're welcome.",
        },
    },
})

Catalog.Register("semantic.apology", {
    variants = {
        {
            id = "semantic.apology.stressed",
            templateID = "semantic.social.apology.stressed",
            fallback = "I know things are tense. Let's keep it calm.",
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
            fallback = "It's okay. We can put that behind us.",
            when = { socialStyle = { "friendly", "protective" } },
            priority = 3,
        },
        {
            id = "semantic.apology.trusted",
            templateID = "semantic.social.apology.trusted",
            fallback = "I appreciate you saying that. We're all under pressure.",
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
            fallback = "All right. Let's leave it there.",
            when = { socialStyle = "withdrawn" },
            priority = 1,
        },
        {
            id = "semantic.apology.default",
            templateID = "semantic.social.apology.default",
            fallback = "Noted. Let's move on.",
        },
    },
})

Catalog.Register("semantic.compliment", {
    variants = {
        {
            id = "semantic.compliment.default",
            templateID = "semantic.social.compliment.default",
            fallback = "Thanks. That's kind of you.",
        },
        {
            id = "semantic.compliment.alternate",
            templateID = "semantic.social.compliment.alternate",
            fallback = "I appreciate you saying that.",
        },
        {
            id = "semantic.compliment.friendly",
            templateID = "semantic.social.compliment.friendly",
            fallback = "Thanks. You seem pretty great yourself.",
            when = { socialStyle = { "friendly", "protective" } },
            priority = 3,
        },
        {
            id = "semantic.compliment.trusted",
            templateID = "semantic.social.compliment.trusted",
            fallback = "Thanks. Hearing that from you means a lot.",
            when = { relationshipState = { "Member", "Lover" } },
            priority = 2,
        },
        {
            id = "semantic.compliment.withdrawn",
            templateID = "semantic.social.compliment.withdrawn",
            fallback = "Oh. Thank you, that's kind of you.",
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
            fallback = "All right, I'll take care of it.",
            when = { hasPendingRequest = true },
            priority = 1,
        },
        {
            id = "semantic.accept.default",
            templateID = "semantic.social.acknowledged",
            fallback = "All right.",
        },
    },
})

Catalog.Register("semantic.conversation.acknowledged", {
    variants = {
        {
            id = "semantic.conversation.acknowledged.friendly",
            templateID = "semantic.conversation.acknowledged.friendly",
            fallback = "All right. Ask if you want to talk about it more.",
            when = { socialStyle = { "friendly", "protective" } },
            priority = 2,
        },
        {
            id = "semantic.conversation.acknowledged.withdrawn",
            templateID = "semantic.conversation.acknowledged.withdrawn",
            fallback = "All right. We can leave it there for now.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.conversation.acknowledged.default",
            templateID = "semantic.conversation.acknowledged.default",
            fallback = "All right. Ask if you want to talk about it more.",
        },
    },
})

Catalog.Register("semantic.refuse", {
    variants = {
        {
            id = "semantic.refuse.stressed",
            templateID = "semantic.social.dispute_stressed",
            fallback = "I hear you, but I can't take that on while I'm this tense.",
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
            fallback = "No problem. I'll leave it.",
            when = { hasPendingRequest = true },
            priority = 5,
        },
        {
            id = "semantic.refuse.friendly",
            templateID = "semantic.social.dispute_friendly",
            fallback = "I see it differently, but we're okay.",
            when = { socialStyle = { "friendly", "protective" } },
            priority = 2,
        },
        {
            id = "semantic.refuse.trusted",
            templateID = "semantic.social.dispute_trusted",
            fallback = "I respect that. I still don't agree.",
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
            fallback = "Let's leave it there.",
            when = { socialStyle = "withdrawn" },
            priority = 1,
        },
        {
            id = "semantic.refuse.default",
            templateID = "semantic.social.acknowledged",
            fallback = "No.",
        },
    },
})

Catalog.Register("semantic.gossip", {
    variants = {
        {
            id = "semantic.gossip.memory",
            templateID = "semantic.gossip.memory",
            fallback = "I have something I remember about that.",
            when = { memoryAvailable = true },
            priority = 2,
        },
        {
            id = "semantic.gossip.unknown",
            templateID = "semantic.gossip.unknown",
            fallback = "I haven't heard anything about that yet.",
        },
    },
})

Catalog.Register("semantic.self_reflection", {
    variants = {
        {
            id = "semantic.self_reflection.friendly",
            templateID = "semantic.social.self_reflection.friendly",
            fallback = "Hey. Don't talk about yourself like that. You matter.",
            when = { socialStyle = { "friendly", "protective" } },
            priority = 4,
        },
        {
            id = "semantic.self_reflection.trusted",
            templateID = "semantic.social.self_reflection.trusted",
            fallback = "You're harder on yourself than you need to be.",
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
            fallback = "Don't make a habit of saying things like that.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.self_reflection.stressed",
            templateID = "semantic.social.self_reflection.stressed",
            fallback = "We've all made mistakes. Focus on what comes next.",
            when = { emotionType = { "stress", "panic" } },
            priority = 1,
        },
        {
            id = "semantic.self_reflection.default",
            templateID = "semantic.social.self_reflection.default",
            fallback = "Don't talk about yourself like that.",
        },
    },
})

Catalog.Register("semantic.identity.evasion", {
    variants = {
        {
            id = "semantic.identity.evasion.untrustworthy",
            templateID = "semantic.identity.evasion.untrustworthy",
            fallback = "You avoided my question. I can't trust you with my name.",
            when = { identityTrust = "untrustworthy" },
            priority = 5,
        },
        {
            id = "semantic.identity.evasion.friendly",
            templateID = "semantic.identity.evasion.friendly",
            fallback = "I asked you your name. Changing the subject makes me question your honesty.",
            when = { socialStyle = { "friendly", "protective" } },
            priority = 3,
        },
        {
            id = "semantic.identity.evasion.withdrawn",
            templateID = "semantic.identity.evasion.withdrawn",
            fallback = "Forget it. Keep your name to yourself; I don't trust evasive people.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.identity.evasion.default",
            templateID = "semantic.identity.evasion.default",
            fallback = "You avoided my question. That makes you seem untrustworthy.",
        },
    },
})


return true
