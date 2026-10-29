PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.ResponseCatalog
if type(Catalog) ~= "table" or type(Catalog.Register) ~= "function" then
    return false
end

local CONTENT_OWNER = "projecthoomans.dialogue_content.events"

local function followUp(id, fallback, reference)
    return {
        id = "semantic.followup.event." .. id,
        labelKey = "UI_PNC_SemanticFollowUp_" .. id,
        labelFallback = fallback,
        utteranceKey = "UI_PNC_SemanticFollowUp_" .. id,
        utteranceFallback = fallback,
        frame = {
            subject = "CONTEXT_REFERENCE",
            reference = reference,
        },
    }
end

local HORDE_CHOICE_KEYS = {
    engage = "UI_PNC_Conversation_Content_SemanticCombatHordeChoiceEngageNeutral01",
    avoid = "UI_PNC_Conversation_Content_SemanticCombatHordeChoiceAvoidNeutral01",
    hold = "UI_PNC_Conversation_Content_SemanticCombatHordeChoiceHoldNeutral01",
}

local function tacticalChoice(id, fallback, action)
    local key = HORDE_CHOICE_KEYS[id]
    return {
        id = "semantic.combat.horde.choice." .. id,
        labelKey = key,
        labelFallback = fallback,
        utteranceKey = key,
        utteranceFallback = fallback,
        frame = {
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = action,
            target = "SELF",
        },
    }
end

local HORDE_TACTICAL_OFFERS = {
    tacticalChoice("engage", "Take them.", "COMBAT_ENGAGE"),
    tacticalChoice("avoid", "Go around.", "COMBAT_AVOID"),
    tacticalChoice("hold", "Hold for now.", "COMBAT_HOLD"),
}

local FOLLOW_UP_OFFERS = {
    horde = {
        followUp("location", "Where are they?", "EVENT_LOCATION"),
        followUp("quantity", "How many?", "EVENT_QUANTITY"),
        followUp("happened", "What happened?", "EVENT_WHAT_HAPPENED"),
    },
    combat = {
        followUp("happened", "What happened?", "EVENT_WHAT_HAPPENED"),
    },
    kill = {
        followUp("happened", "What happened?", "EVENT_WHAT_HAPPENED"),
        followUp("quantity", "How many are around?", "EVENT_QUANTITY"),
        followUp("health", "Are you okay?", "EVENT_HEALTH"),
        followUp("next", "What now?", "EVENT_NEXT"),
    },
    retreat = {
        followUp("happened", "What happened?", "EVENT_WHAT_HAPPENED"),
    },
    medical = {
        followUp("happened", "What happened?", "EVENT_WHAT_HAPPENED"),
        followUp("attacker", "Who hurt you?", "EVENT_ATTACKER"),
        followUp("need", "What do you need?", "EVENT_NEED"),
    },
    leader = {
        followUp("deceased", "Who died?", "EVENT_DECEASED"),
        followUp("happened", "What happened?", "EVENT_WHAT_HAPPENED"),
        followUp("next", "What do we do now?", "EVENT_NEXT"),
    },
    abandonment = {
        followUp("health", "Are you hurt?", "EVENT_HEALTH"),
        followUp("pursuer", "Who was after you?", "EVENT_PURSUER"),
    },
    safety = {
        followUp("happened", "What happened?", "EVENT_WHAT_HAPPENED"),
        followUp("location", "Where are they?", "EVENT_LOCATION"),
        followUp("what", "What is it?", "EVENT_WHAT"),
    },
    corpse = {
        followUp("deceased", "Who died?", "EVENT_DECEASED"),
        followUp("happened", "What happened?", "EVENT_WHAT_HAPPENED"),
    },
}

local function plan(poolID, act, topic, templateID, offers)
    return {
        dialogueAct = act,
        sourcePoolID = poolID,
        topic = topic,
        turns = { {
            segments = {
                { kind = "translation", templateID = templateID },
            },
            offers = offers or {},
        } },
    }
end

local function response(poolID, id, when, priority, act, topic, offers,
    templatePrefix)
    local templateID = (templatePrefix or poolID) .. "." .. id
    return {
        id = templateID,
        templateID = templateID,
        contentOwner = CONTENT_OWNER,
        when = when,
        priority = priority or 0,
        plan = plan(poolID, act, topic, templateID, offers),
    }
end

Catalog.Register("semantic.flow.farewell", {
    variants = {
        response(
            "semantic.flow.farewell",
            "friendly",
            { socialStyle = { "friendly", "protective" } },
            2,
            "FAREWELL",
            "farewell"
        ),
        response(
            "semantic.flow.farewell",
            "default",
            nil,
            0,
            "FAREWELL",
            "farewell"
        ),
    },
})

Catalog.Register("semantic.medical.distress", {
    variants = {
        response(
            "semantic.medical.distress",
            "mercy",
            { downedAudience = "hostile", downedNeed = "mercy" },
            5,
            "REQUEST",
            "medical_distress",
            FOLLOW_UP_OFFERS.medical
        ),
        response(
            "semantic.medical.distress",
            "urgent",
            { downedNeed = { "bleedout", "rescue" } },
            4,
            "REQUEST",
            "medical_distress",
            FOLLOW_UP_OFFERS.medical
        ),
        response(
            "semantic.medical.distress",
            "default",
            nil,
            0,
            "REQUEST",
            "medical_distress",
            FOLLOW_UP_OFFERS.medical
        ),
    },
})

Catalog.Register("semantic.leader_loss.reaction", {
    variants = {
        response(
            "semantic.leader_loss",
            "devoted",
            { leaderGrief = "devoted" },
            4,
            "REACT",
            "leader_loss",
            FOLLOW_UP_OFFERS.leader,
            "semantic.leader_loss"
        ),
        response(
            "semantic.leader_loss",
            "dissent",
            { leaderGrief = "dissent" },
            3,
            "REACT",
            "leader_loss",
            FOLLOW_UP_OFFERS.leader,
            "semantic.leader_loss"
        ),
        response(
            "semantic.leader_loss",
            "close",
            { leaderGrief = "close" },
            2,
            "REACT",
            "leader_loss",
            FOLLOW_UP_OFFERS.leader,
            "semantic.leader_loss"
        ),
        response(
            "semantic.leader_loss",
            "colonist",
            { leaderGrief = "colonist" },
            2,
            "REACT",
            "leader_loss",
            FOLLOW_UP_OFFERS.leader,
            "semantic.leader_loss"
        ),
        response(
            "semantic.leader_loss",
            "distant",
            { leaderGrief = "distant" },
            2,
            "REACT",
            "leader_loss",
            FOLLOW_UP_OFFERS.leader,
            "semantic.leader_loss"
        ),
        response(
            "semantic.leader_loss",
            "default",
            nil,
            0,
            "REACT",
            "leader_loss",
            FOLLOW_UP_OFFERS.leader,
            "semantic.leader_loss"
        ),
    },
})

local KILL_REACTION_STYLES = {
    "aggressive", "supportive", "shaken", "brave",
    "reserved", "cold", "practical",
}
for _, role in ipairs({ "witness", "killer" }) do
    for _, style in ipairs(KILL_REACTION_STYLES) do
        local poolID = "semantic.combat.kill." .. role .. "." .. style
        local variants = {}
        for variantIndex = 1, 3 do
            variants[#variants + 1] = response(
                poolID,
                string.format(
                    "kill_%s_%s_%02d", role, style, variantIndex
                ),
                nil,
                0,
                "REACT",
                "combat",
                FOLLOW_UP_OFFERS.kill,
                "semantic.combat.reaction"
            )
        end
        Catalog.Register(poolID, { variants = variants })
    end
end

Catalog.Register("semantic.combat.horde.prompt", {
    variants = {
        response(
            "semantic.combat.horde.prompt",
            "eager",
            { combatReactionStyle = { "aggressive", "brave" } },
            4,
            "QUESTION",
            "combat",
            HORDE_TACTICAL_OFFERS
        ),
        response(
            "semantic.combat.horde.prompt",
            "shaken",
            { combatReactionStyle = "shaken" },
            4,
            "QUESTION",
            "combat",
            HORDE_TACTICAL_OFFERS
        ),
        response(
            "semantic.combat.horde.prompt",
            "reserved",
            { combatReactionStyle = { "reserved", "cold" } },
            3,
            "QUESTION",
            "combat",
            HORDE_TACTICAL_OFFERS
        ),
        response(
            "semantic.combat.horde.prompt",
            "default",
            nil,
            0,
            "QUESTION",
            "combat",
            HORDE_TACTICAL_OFFERS
        ),
    },
})

Catalog.Register("semantic.combat.horde", {
    variants = {
        response(
            "semantic.combat.horde",
            "escalated",
            { hordePhase = "escalated" },
            4,
            "WARN",
            "combat",
            FOLLOW_UP_OFFERS.horde
        ),
        response(
            "semantic.combat.horde",
            "deescalated",
            { hordePhase = "deescalated" },
            3,
            "REACT",
            "combat",
            FOLLOW_UP_OFFERS.horde
        ),
        response(
            "semantic.combat.horde",
            "started",
            { hordePhase = { "started", nil } },
            2,
            "WARN",
            "combat",
            FOLLOW_UP_OFFERS.horde
        ),
        response(
            "semantic.combat.horde",
            "default",
            nil,
            0,
            "WARN",
            "combat",
            FOLLOW_UP_OFFERS.horde
        ),
    },
})

Catalog.Register("semantic.combat.reaction", {
    variants = {
        response(
            "semantic.combat.reaction",
            "retreat",
            { eventType = "zombie_stamina_retreat" },
            4,
            "REACT",
            "combat",
            FOLLOW_UP_OFFERS.retreat
        ),
        response(
            "semantic.combat.reaction",
            "threat",
            { eventType = { "combat_awareness", "zombie_horde_detected" } },
            3,
            "REACT",
            "combat",
            FOLLOW_UP_OFFERS.horde
        ),
        response(
            "semantic.combat.reaction",
            "default",
            nil,
            0,
            "REACT",
            "combat",
            FOLLOW_UP_OFFERS.combat
        ),
    },
})

Catalog.Register("semantic.companion.reaction", {
    variants = {
        response(
            "semantic.companion.reaction",
            "camp_rejected",
            {
                eventType = "companion_command_rejection",
                commandID = "camp",
            },
            8,
            "REACT",
            "camp"
        ),
        response(
            "semantic.companion.reaction",
            "abandonment",
            { eventType = { "follower_abandoned_zombie",
                "follower_abandoned_hostile_npc" } },
            3,
            "REACT",
            "companion_relationship",
            FOLLOW_UP_OFFERS.abandonment
        ),
        response(
            "semantic.companion.reaction",
            "default",
            nil,
            0,
            "ACK",
            "companion_acknowledgement"
        ),
    },
})

Catalog.Register("semantic.social.reaction", {
    variants = {
        response(
            "semantic.social.reaction",
            "default",
            nil,
            0,
            "REACT",
            "social_reaction"
        ),
    },
})

Catalog.Register("semantic.conversation.safety", {
    variants = {
        response(
            "semantic.conversation.safety",
            "danger",
            { eventType = "conversation_safety" },
            2,
            "WARN",
            "safety",
            FOLLOW_UP_OFFERS.safety
        ),
        response(
            "semantic.conversation.safety",
            "default",
            nil,
            0,
            "WARN",
            "safety"
        ),
    },
})

Catalog.Register("semantic.corpse.reaction", {
    variants = {
        response(
            "semantic.corpse.reaction",
            "revenge",
            { corpseRevenge = true },
            3,
            "REACT",
            "corpse_reaction"
        ),
        response(
            "semantic.corpse.reaction",
            "default",
            nil,
            0,
            "REACT",
            "corpse_reaction",
            FOLLOW_UP_OFFERS.corpse
        ),
    },
})

return true
