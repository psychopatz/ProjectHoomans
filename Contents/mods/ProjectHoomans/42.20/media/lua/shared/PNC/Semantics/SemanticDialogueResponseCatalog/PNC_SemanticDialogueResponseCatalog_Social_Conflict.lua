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

Catalog.Register("semantic.player_assaulted_npc", {
    variants = {
        {
            id = "semantic.player_assaulted_npc.shaken",
            templateID = "semantic.combat.player_assaulted.shaken",
            fallback = "What the hell?! Stay back!",
            when = { combatReactionStyle = "shaken" },
            priority = 5,
        },
        {
            id = "semantic.player_assaulted_npc.aggressive",
            templateID = "semantic.combat.player_assaulted.aggressive",
            fallback = "You just made a big mistake.",
            when = { combatReactionStyle = "aggressive" },
            priority = 5,
        },
        {
            id = "semantic.player_assaulted_npc.brave",
            templateID = "semantic.combat.player_assaulted.brave",
            fallback = "That's it. You're done.",
            when = { combatReactionStyle = "brave" },
            priority = 4,
        },
        {
            id = "semantic.player_assaulted_npc.reserved",
            templateID = "semantic.combat.player_assaulted.reserved",
            fallback = "Back off. Now.",
            when = { combatReactionStyle = "reserved" },
            priority = 3,
        },
        {
            id = "semantic.player_assaulted_npc.default",
            templateID = "semantic.combat.player_assaulted.default",
            fallback = "Why did you do that?!",
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
-- response authority; wording is supplied by Dialogue Content.
Catalog.Register("semantic.emote.reply", {
    variants = {
        {
            id = "semantic.emote.reply.thumbsup.active",
            templateID = "semantic.emote.reply.thumbsup.active",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "thumbsup", previousTopic = "water" },
            priority = 4,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.emote.reply",
                topic = "water",
                turns = { { segments = {
                    { kind = "translation", templateID = "semantic.emote.reply.thumbsup.active" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.thumbsup",
            templateID = "semantic.emote.reply.thumbsup",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "thumbsup" },
            priority = 2,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.emote.reply",
                topic = "acknowledgement",
                turns = { { segments = {
                    { kind = "translation", templateID = "semantic.emote.reply.thumbsup" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.thumbsdown",
            templateID = "semantic.emote.reply.thumbsdown",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "thumbsdown" },
            priority = 2,
            plan = {
                dialogueAct = "DISAPPROVE",
                sourcePoolID = "semantic.emote.reply",
                topic = "disapproval",
                turns = { { segments = {
                    { kind = "translation", templateID = "semantic.emote.reply.thumbsdown" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.insult",
            templateID = "semantic.emote.reply.insult",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "insult" },
            priority = 2,
            plan = {
                dialogueAct = "INSULT",
                sourcePoolID = "semantic.emote.reply",
                topic = "hostility",
                turns = { { segments = {
                    { kind = "translation", templateID = "semantic.emote.reply.insult" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.wavehi",
            templateID = "semantic.emote.reply.wavehi",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "wavehi" },
            priority = 2,
            plan = {
                dialogueAct = "GREET",
                sourcePoolID = "semantic.emote.reply",
                topic = "greeting",
                turns = { { segments = {
                    { kind = "translation", templateID = "semantic.emote.reply.wavehi" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.wavebye",
            templateID = "semantic.emote.reply.wavebye",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "wavebye" },
            priority = 2,
            plan = {
                dialogueAct = "FAREWELL",
                sourcePoolID = "semantic.emote.reply",
                topic = "farewell",
                turns = { { segments = {
                    { kind = "translation", templateID = "semantic.emote.reply.wavebye" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.thankyou",
            templateID = "semantic.emote.reply.thankyou",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "thankyou" },
            priority = 2,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.emote.reply",
                topic = "thanks",
                turns = { { segments = {
                    { kind = "translation", templateID = "semantic.emote.reply.thankyou" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.clap",
            templateID = "semantic.emote.reply.clap",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "clap" },
            priority = 2,
            plan = {
                dialogueAct = "PRAISE",
                sourcePoolID = "semantic.emote.reply",
                topic = "praise",
                turns = { { segments = {
                    { kind = "translation", templateID = "semantic.emote.reply.clap" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.salute",
            templateID = "semantic.emote.reply.salute",
            contentOwner = "projecthoomans.dialogue_content.commands_emotes",
            when = { action = "salute" },
            priority = 2,
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.emote.reply",
                topic = "acknowledgement",
                turns = { { segments = {
                    { kind = "translation", templateID = "semantic.emote.reply.salute" },
                } } },
            },
        },
        {
            id = "semantic.emote.reply.default",
            templateID = "semantic.emote.reply.default",
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.emote.reply",
                topic = "social_reaction",
                turns = { { segments = {
                    { kind = "translation", templateID = "semantic.emote.reply.default" },
                } } },
            },
        },
    },
})


return true
