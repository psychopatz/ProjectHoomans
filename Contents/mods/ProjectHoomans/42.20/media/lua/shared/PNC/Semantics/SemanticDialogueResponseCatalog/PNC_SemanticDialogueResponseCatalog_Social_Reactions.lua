PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

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
