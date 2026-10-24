-- Authored deterministic response pools for the semantic dialogue catalog.
-- This module owns response content; selection and validation stay in the
-- catalog entry so all callers share one bounded contract.
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

Catalog.Register("semantic.flow.farewell", {
    variants = {
        {
            id = "semantic.flow.farewell.friendly",
            templateID = "semantic.flow.farewell.friendly",
            fallback = "Take care. I will see you soon.",
            when = { socialStyle = { "friendly", "protective" } },
            priority = 2,
            plan = {
                dialogueAct = "FAREWELL",
                sourcePoolID = "semantic.flow.farewell",
                topic = "farewell",
                turns = { { segments = {
                    { kind = "literal", text = "Take care. I will see you soon." },
                } } },
            },
        },
        {
            id = "semantic.flow.farewell.default",
            templateID = "semantic.flow.farewell.default",
            fallback = "Take care.",
            plan = {
                dialogueAct = "FAREWELL",
                sourcePoolID = "semantic.flow.farewell",
                topic = "farewell",
                turns = { { segments = {
                    { kind = "literal", text = "Take care." },
                } } },
            },
        },
    },
})

Catalog.Register("semantic.medical.distress", {
    variants = {
        {
            id = "semantic.medical.distress.mercy",
            templateID = "semantic.medical.distress.mercy",
            fallback = "Please. I need help with this wound.",
            when = { downedAudience = "hostile", downedNeed = "mercy" },
            priority = 5,
            plan = {
                dialogueAct = "REQUEST",
                sourcePoolID = "semantic.medical.distress",
                topic = "medical_distress",
                turns = { { segments = {
                    { kind = "literal", text = "Please. I need help with this wound." },
                } } },
            },
        },
        {
            id = "semantic.medical.distress.urgent",
            templateID = "semantic.medical.distress.urgent",
            fallback = "I am hurt. I need help now.",
            when = { downedNeed = { "bleedout", "rescue" } },
            priority = 4,
            plan = {
                dialogueAct = "REQUEST",
                sourcePoolID = "semantic.medical.distress",
                topic = "medical_distress",
                turns = { { segments = {
                    { kind = "literal", text = "I am hurt. I need help now." },
                } } },
            },
        },
        {
            id = "semantic.medical.distress.default",
            templateID = "semantic.medical.distress.default",
            fallback = "I need help with this wound.",
            plan = {
                dialogueAct = "REQUEST",
                sourcePoolID = "semantic.medical.distress",
                topic = "medical_distress",
                turns = { { segments = {
                    { kind = "literal", text = "I need help with this wound." },
                } } },
            },
        },
    },
})

Catalog.Register("semantic.leader_loss.reaction", {
    variants = {
        {
            id = "semantic.leader_loss.devoted",
            templateID = "semantic.leader_loss.devoted",
            fallback = "We lost someone important. We need to stay together.",
            when = { leaderGrief = "devoted" },
            priority = 4,
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.leader_loss.reaction",
                topic = "leader_loss",
                turns = { { segments = {
                    { kind = "literal", text = "We lost someone important. We need to stay together." },
                } } },
            },
        },
        {
            id = "semantic.leader_loss.dissent",
            templateID = "semantic.leader_loss.dissent",
            fallback = "The old order is gone. What happens next is up to us.",
            when = { leaderGrief = "dissent" },
            priority = 3,
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.leader_loss.reaction",
                topic = "leader_loss",
                turns = { { segments = {
                    { kind = "literal", text = "The old order is gone. What happens next is up to us." },
                } } },
            },
        },
        {
            id = "semantic.leader_loss.default",
            templateID = "semantic.leader_loss.default",
            fallback = "We lost our leader. We need to decide what comes next.",
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.leader_loss.reaction",
                topic = "leader_loss",
                turns = { { segments = {
                    { kind = "literal", text = "We lost our leader. We need to decide what comes next." },
                } } },
            },
        },
    },
})

Catalog.Register("semantic.combat.reaction", {
    variants = {
        {
            id = "semantic.combat.reaction.threat",
            templateID = "semantic.combat.reaction.threat",
            fallback = "That threat is down. Stay alert.",
            when = { eventType = { "combat_awareness", "zombie_horde_detected" } },
            priority = 3,
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.combat.reaction",
                topic = "combat",
                turns = { { segments = {
                    { kind = "literal", text = "That threat is down. Stay alert." },
                } } },
            },
        },
        {
            id = "semantic.combat.reaction.default",
            templateID = "semantic.combat.reaction.default",
            fallback = "Good work. Keep watching the area.",
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.combat.reaction",
                topic = "combat",
                turns = { { segments = {
                    { kind = "literal", text = "Good work. Keep watching the area." },
                } } },
            },
        },
    },
})

Catalog.Register("semantic.companion.reaction", {
    variants = {
        {
            id = "semantic.companion.reaction.camp_rejected",
            templateID = "semantic.companion.reaction.camp_rejected",
            fallback = "I can't find a safe room or campfire nearby.",
            compatibilityFlavorID = "camp_rejected",
            when = {
                eventType = "companion_command_rejection",
                commandID = "camp",
            },
            priority = 8,
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.companion.reaction",
                topic = "camp",
                turns = { { segments = {
                    { kind = "literal", text = "I can't find a safe room or campfire nearby." },
                } } },
            },
        },
        {
            id = "semantic.companion.reaction.abandonment",
            templateID = "semantic.companion.reaction.abandonment",
            fallback = "Stay with me next time. We watch each other's backs.",
            when = { eventType = { "follower_abandoned_zombie", "follower_abandoned_hostile_npc" } },
            priority = 3,
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.companion.reaction",
                topic = "companion_relationship",
                turns = { { segments = {
                    { kind = "literal", text = "Stay with me next time. We watch each other's backs." },
                } } },
            },
        },
        {
            id = "semantic.companion.reaction.default",
            templateID = "semantic.companion.reaction.default",
            fallback = "I heard you. We will handle it together.",
            plan = {
                dialogueAct = "ACK",
                sourcePoolID = "semantic.companion.reaction",
                topic = "companion_acknowledgement",
                turns = { { segments = {
                    { kind = "literal", text = "I heard you. We will handle it together." },
                } } },
            },
        },
    },
})

Catalog.Register("semantic.social.reaction", {
    variants = {
        {
            id = "semantic.social.reaction.default",
            templateID = "semantic.social.reaction.default",
            fallback = "I hear you.",
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.social.reaction",
                topic = "social_reaction",
                turns = { { segments = {
                    { kind = "literal", text = "I hear you." },
                } } },
            },
        },
    },
})

Catalog.Register("semantic.conversation.safety", {
    variants = {
        {
            id = "semantic.conversation.safety.danger",
            templateID = "semantic.conversation.safety.danger",
            fallback = "Watch out. We need to move now.",
            when = { eventType = "conversation_safety" },
            priority = 2,
            plan = {
                dialogueAct = "WARN",
                sourcePoolID = "semantic.conversation.safety",
                topic = "safety",
                turns = { { segments = {
                    { kind = "literal", text = "Watch out. We need to move now." },
                } } },
            },
        },
        {
            id = "semantic.conversation.safety.default",
            templateID = "semantic.conversation.safety.default",
            fallback = "Stay alert.",
            plan = {
                dialogueAct = "WARN",
                sourcePoolID = "semantic.conversation.safety",
                topic = "safety",
                turns = { { segments = {
                    { kind = "literal", text = "Stay alert." },
                } } },
            },
        },
    },
})

Catalog.Register("semantic.corpse.reaction", {
    variants = {
        {
            id = "semantic.corpse.reaction.revenge",
            templateID = "semantic.corpse.reaction.revenge",
            fallback = "Someone is going to answer for this.",
            compatibilityFlavorID = "corpse_seen_revenge_unknown",
            when = { corpseRevenge = true },
            priority = 3,
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.corpse.reaction",
                topic = "corpse_reaction",
                turns = { { segments = {
                    { kind = "literal", text = "Someone is going to answer for this." },
                } } },
            },
        },
        {
            id = "semantic.corpse.reaction.default",
            templateID = "semantic.corpse.reaction.default",
            fallback = "Someone died here. We should remember that.",
            compatibilityFlavorID = "corpse_seen_unknown",
            plan = {
                dialogueAct = "REACT",
                sourcePoolID = "semantic.corpse.reaction",
                topic = "corpse_reaction",
                turns = { { segments = {
                    { kind = "literal", text = "Someone died here. We should remember that." },
                } } },
            },
        },
    },
})

return true
