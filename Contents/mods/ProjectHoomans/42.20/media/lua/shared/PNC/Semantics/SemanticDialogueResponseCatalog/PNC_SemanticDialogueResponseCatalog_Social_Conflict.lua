PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

Catalog.Register("semantic.hostile_remark", {
    variants = {
        {
            id = "semantic.hostile.escalated",
            templateID = "semantic.social.hostile_escalated",
            fallback = "That's enough. Keep it up and we're done.",
            when = { hostilityCount = { 2, 3, 4, 5, 6 } },
            priority = 4,
        },
        {
            id = "semantic.hostile.default",
            templateID = "semantic.social.hostile_boundary",
            fallback = "Don't talk to me like that.",
        },
        {
            id = "semantic.hostile.short",
            templateID = "semantic.social.hostile_short",
            fallback = "Watch your mouth.",
        },
        {
            id = "semantic.hostile.withdrawn",
            templateID = "semantic.social.hostile_withdrawn",
            fallback = "Then leave me alone.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.hostile.busy",
            templateID = "semantic.social.hostile_busy",
            fallback = "Not now. I have enough to deal with.",
            when = { busy = true },
            priority = 2,
        },
        {
            id = "semantic.hostile.stressed",
            templateID = "semantic.social.hostile_stressed",
            fallback = "I've had enough already.",
            when = {
                emotionType = { "stress", "panic" },
                emotionUrgency = {
                    "moderate", "severe", "critical", "emergency",
                },
            },
            priority = 2,
        },
    },
})

Catalog.Register("semantic.threat", {
    variants = {
        {
            id = "semantic.threat.stressed",
            templateID = "semantic.social.threat_stressed",
            fallback = "I've had enough. Back off before this gets worse.",
            when = {
                emotionType = { "stress", "panic" },
                emotionUrgency = {
                    "moderate", "severe", "critical", "emergency",
                },
            },
            priority = 5,
        },
        {
            id = "semantic.threat.withdrawn",
            templateID = "semantic.social.threat_withdrawn",
            fallback = "Keep your distance. I'm not discussing this.",
            when = { socialStyle = "withdrawn" },
            priority = 2,
        },
        {
            id = "semantic.threat.trusted",
            templateID = "semantic.social.threat_trusted",
            fallback = "Don't make this personal. Step back.",
            when = {
                relationshipState = {
                    "Friend", "Trusted", "Ally", "Member", "Lover",
                },
            },
            priority = 1,
        },
        {
            id = "semantic.threat.default",
            templateID = "semantic.social.threat_boundary",
            fallback = "Back off.",
        },
        {
            id = "semantic.threat.firm",
            templateID = "semantic.social.threat_firm",
            fallback = "Don't threaten me.",
        },
        {
            id = "semantic.threat.busy",
            templateID = "semantic.social.threat_busy",
            fallback = "Pick another fight.",
            when = { busy = true },
            priority = 3,
        },
    },
})

-- Vanilla emotes enter the semantic lifecycle as acts.  These pools are the
-- response authority; the old role/tier Flavor IDs remain content aliases
-- only and are not consulted for the selected reaction.
Catalog.Register("semantic.emote.reply", {
    variants = {
        {
            id = "semantic.emote.reply.thumbsup.active",
            templateID = "semantic.emote.reply.thumbsup.active",
            fallback = "Good. Let's keep moving on this.",
            compatibilityFlavorID = "vanilla_emote_thumbsup_npc_neutral",
            when = { action = "thumbsup", previousTopic = "water" },
            priority = 4,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.emote.reply",
                topic = "water",
                turns = { { segments = {
                    { kind = "literal", text = "Good. Let's keep moving on this." },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.thumbsup",
            templateID = "semantic.emote.reply.thumbsup",
            fallback = "Good.",
            compatibilityFlavorID = "vanilla_emote_thumbsup_npc_neutral",
            when = { action = "thumbsup" },
            priority = 2,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.emote.reply",
                topic = "acknowledgement",
                turns = { { segments = {
                    { kind = "literal", text = "Good." },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.thumbsdown",
            templateID = "semantic.emote.reply.thumbsdown",
            fallback = "I got the message. Tell me what is wrong.",
            compatibilityFlavorID = "vanilla_emote_thumbsdown_npc_neutral",
            when = { action = "thumbsdown" },
            priority = 2,
            plan = {
                dialogueAct = "DISAPPROVE",
                sourcePoolID = "semantic.emote.reply",
                topic = "disapproval",
                turns = { { segments = {
                    { kind = "literal", text = "I got the message. Tell me what is wrong." },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.insult",
            templateID = "semantic.emote.reply.insult",
            fallback = "Keep it respectful.",
            compatibilityFlavorID = "vanilla_emote_insult_npc_neutral",
            when = { action = "insult" },
            priority = 2,
            plan = {
                dialogueAct = "INSULT",
                sourcePoolID = "semantic.emote.reply",
                topic = "hostility",
                turns = { { segments = {
                    { kind = "literal", text = "Keep it respectful." },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.wavehi",
            templateID = "semantic.emote.reply.wavehi",
            fallback = "Hey.",
            compatibilityFlavorID = "vanilla_emote_wavehi_npc_neutral",
            when = { action = "wavehi" },
            priority = 2,
            plan = {
                dialogueAct = "GREET",
                sourcePoolID = "semantic.emote.reply",
                topic = "greeting",
                turns = { { segments = {
                    { kind = "literal", text = "Hey." },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.wavebye",
            templateID = "semantic.emote.reply.wavebye",
            fallback = "Take care.",
            compatibilityFlavorID = "vanilla_emote_wavebye_npc_neutral",
            when = { action = "wavebye" },
            priority = 2,
            plan = {
                dialogueAct = "FAREWELL",
                sourcePoolID = "semantic.emote.reply",
                topic = "farewell",
                turns = { { segments = {
                    { kind = "literal", text = "Take care." },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.thankyou",
            templateID = "semantic.emote.reply.thankyou",
            fallback = "You're welcome.",
            compatibilityFlavorID = "vanilla_emote_thankyou_npc_neutral",
            when = { action = "thankyou" },
            priority = 2,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.emote.reply",
                topic = "thanks",
                turns = { { segments = {
                    { kind = "literal", text = "You're welcome." },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.clap",
            templateID = "semantic.emote.reply.clap",
            fallback = "Thanks. It was a small win.",
            compatibilityFlavorID = "vanilla_emote_clap_npc_neutral",
            when = { action = "clap" },
            priority = 2,
            plan = {
                dialogueAct = "PRAISE",
                sourcePoolID = "semantic.emote.reply",
                topic = "praise",
                turns = { { segments = {
                    { kind = "literal", text = "Thanks. It was a small win." },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.salute",
            templateID = "semantic.emote.reply.salute",
            fallback = "Stay sharp.",
            compatibilityFlavorID = "vanilla_emote_salute_npc_neutral",
            when = { action = "salute" },
            priority = 2,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.emote.reply",
                topic = "acknowledgement",
                turns = { { segments = {
                    { kind = "literal", text = "Stay sharp." },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.default",
            templateID = "semantic.emote.reply.default",
            fallback = "I hear you.",
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.emote.reply",
                topic = "social_reaction",
                turns = { { segments = {
                    { kind = "literal", text = "I hear you." },
                } } },
            },
        },
    },
})


return true
