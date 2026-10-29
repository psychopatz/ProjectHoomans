-- Semantic reaction-family resolver for event-driven NPC speech.
--
-- Domain/event adapters provide authoritative facts. This module selects a
-- bounded ResponsePlan/realization and returns it to the presentation layer.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Reactions = PNC.Semantics.SocialReactions or {}
PNC.Semantics.SocialReactions = Reactions

local Authority = PNC.Semantics.RealizationAuthority
    or require "PNC/Semantics/PNC_SemanticDialogueRealizationAuthority"
local EVENT_OFFER_FIELDS = {
    EVENT_WHAT_HAPPENED = { "summary", "happened", "description" },
    EVENT_LOCATION = { "location", "locationLabel" },
    EVENT_QUANTITY = { "quantity", "count", "countBand" },
    EVENT_ATTACKER = { "attackerName", "attacker" },
    EVENT_NEED = { "need", "needType" },
    EVENT_DECEASED = { "deceasedName", "deceased" },
    EVENT_NEXT = { "nextAction", "next" },
    EVENT_HEALTH = { "health", "healthState" },
    EVENT_PURSUER = { "pursuerName", "pursuer", "attackerName" },
    EVENT_WHAT = { "description", "summary", "what" },
}

Reactions.VERSION = 1

local function hasScalarValue(value)
    if type(value) == "string" or type(value) == "number"
        or type(value) == "boolean"
    then
        return tostring(value) ~= ""
    end
    if type(value) ~= "table" then return false end
    if value.x ~= nil and value.y ~= nil then return true end
    for _, key in ipairs({ "label", "name", "text", "summary", "value" }) do
        if hasScalarValue(value[key]) then return true end
    end
    return false
end

local function eventFact(context)
    local facts = type(context) == "table"
        and context.semanticEventFacts or nil
    if type(facts) ~= "table" then return nil end
    local eventRef = tostring(
        context.eventRef or context.eventID or ""
    )
    if eventRef ~= "" and type(facts[eventRef]) == "table" then
        local fact = facts[eventRef]
        if fact.authoritative == true
            and fact.disclosure ~= false
            and fact.disclosure ~= "private"
        then
            return fact
        end
    end
    if facts.eventRef ~= nil and tostring(facts.eventRef) == eventRef
        and facts.authoritative == true
        and facts.disclosure ~= false
        and facts.disclosure ~= "private"
    then
        return facts
    end
    return nil
end

local function offerSupported(offer, context)
    local frame = type(offer) == "table" and offer.frame or nil
    local reference = frame and frame.reference or nil
    local fields = EVENT_OFFER_FIELDS[tostring(reference or "")]
    local fact
    if not fields then return true end
    fact = eventFact(context)
    if not fact then return false end
    for _, field in ipairs(fields) do
        if hasScalarValue(fact[field]) then return true end
    end
    return false
end

local function filteredPlan(plan, context)
    local output
    if type(plan) ~= "table" or type(plan.turns) ~= "table" then
        return plan, {}
    end
    output = {}
    for key, value in pairs(plan) do output[key] = value end
    output.turns = {}
    local offerIDs = {}
    local seen = {}
    for index, turn in ipairs(plan.turns) do
        local copiedTurn = {}
        for key, value in pairs(turn) do copiedTurn[key] = value end
        copiedTurn.offers = {}
        for _, offer in ipairs(turn.offers or {}) do
            if offerSupported(offer, context) then
                copiedTurn.offers[#copiedTurn.offers + 1] = offer
                local id = offer.id and tostring(offer.id) or ""
                if id ~= "" and not seen[id] and #offerIDs < 8 then
                    seen[id] = true
                    offerIDs[#offerIDs + 1] = id
                end
            end
        end
        output.turns[index] = copiedTurn
    end
    return output, offerIDs
end

local function poolFor(spec)
    if spec.poolID then return tostring(spec.poolID) end
    local eventType = string.lower(tostring(spec.eventType or ""))
    local context = type(spec.context) == "table" and spec.context or {}
    if eventType == "zombie_kill_witnessed"
        or eventType == "zombie_kill_self"
    then
        local role = tostring(context.combatReactionRole or (
            eventType == "zombie_kill_self" and "killer" or "witness"
        ))
        local style = tostring(context.combatReactionStyle or "practical")
        local allowed = {
            aggressive = true, supportive = true, shaken = true,
            brave = true, reserved = true, cold = true, practical = true,
        }
        if role ~= "killer" then role = "witness" end
        if not allowed[style] then style = "practical" end
        return "semantic.combat.kill." .. role .. "." .. style
    end
    if eventType == "hostile_npc_kill_self" then
        local style = tostring(context.combatReactionStyle or "practical")
        local allowed = {
            aggressive = true, supportive = true, shaken = true,
            brave = true, reserved = true, cold = true, practical = true,
        }
        if not allowed[style] then style = "practical" end
        return "semantic.combat.human_kill." .. style
    end
    if eventType == "zombie_horde_encounter"
        or eventType == "zombie_horde_detected"
    then
        if context.combatTacticalPrompt == true then
            return "semantic.combat.horde.prompt"
        end
        return "semantic.combat.horde"
    end
    if eventType == "bandit_attack" then
        return "semantic.compat.bandits.hooman_hurt"
    end
    if eventType == "necroa_mask_removed" then
        return "semantic.compat.necroa.mask_warning"
    end
    if eventType == "necroa_player_mask_removed" then
        return "semantic.compat.necroa.player_mask_removed"
    end
    if eventType == "projectalife_meta"
        or eventType == "projectalife_meta_event"
    then
        return "semantic.compat.projectalife.meta"
    end
    if eventType == "projectalife_encounter" then
        return "semantic.compat.projectalife.encounter"
    end
    if eventType == "projectalife_faction_stance"
        or eventType == "projectalife_faction_conflict"
    then
        return "semantic.compat.projectalife.faction"
    end
    if eventType == "companion_dog_greeting" then
        return "semantic.compat.companion_dogs.greeting"
    end
    if eventType == "companion_dog_feed" then
        return "semantic.compat.companion_dogs.feed"
    end
    if eventType == "incapacitated_call"
        or eventType == "social.incapacitated_call"
    then
        return "semantic.medical.distress.call"
    end
    if eventType == "incapacitated_update"
        or eventType == "social.incapacitated_update"
    then
        return "semantic.medical.distress.update"
    end
    if eventType == "incapacitated_repeat"
        or eventType == "social.incapacitated_repeat"
    then
        return "semantic.medical.distress.repeat"
    end
    if eventType == "witnessed_teammate_hurt" then
        return "semantic.medical.distress.teammate"
    end
    if eventType == "treated_wound" then
        return "semantic.medical.distress.treatment"
    end
    if string.find(eventType, "conversation_safety", 1, true) then
        return "semantic.conversation.safety"
    end
    if string.find(eventType, "corpse", 1, true)
        or string.find(eventType, "death_reaction", 1, true)
    then
        return "semantic.corpse.reaction"
    end
    if string.find(eventType, "leader", 1, true)
        or string.find(eventType, "succession", 1, true)
    then
        return "semantic.leader_loss.reaction"
    end
    if string.find(eventType, "incapacitated", 1, true)
        or string.find(eventType, "medical", 1, true)
        or string.find(eventType, "treatment", 1, true)
        or string.find(eventType, "hurt", 1, true)
    then
        return "semantic.medical.distress"
    end
    -- Follower abandonment is a companion event even when its authoritative
    -- cause is a zombie.  Keep this family check ahead of the generic combat
    -- cause check so the event cannot fall through to combat wording.
    if string.find(eventType, "follower", 1, true)
        or string.find(eventType, "companion", 1, true)
    then
        return "semantic.companion.reaction"
    end
    if string.find(eventType, "combat", 1, true)
        or string.find(eventType, "kill", 1, true)
        or string.find(eventType, "horde", 1, true)
        or string.find(eventType, "zombie", 1, true)
    then
        return "semantic.combat.reaction"
    end
    return "semantic.social.reaction"
end

function Reactions.Resolve(spec)
    spec = type(spec) == "table" and spec or {}
    local context = type(spec.context) == "table" and spec.context or {}
    local poolID = poolFor(spec)
    local realization = Authority.Resolve({
        poolID = poolID,
        responsePlanID = spec.responsePlanID or poolID,
        realizationFamily = spec.realizationFamily or poolID,
        act = spec.act or "REACT",
        topic = spec.topic or spec.eventType or "social_reaction",
        context = context,
        salt = spec.salt or spec.eventID or spec.npcID,
        groundedFactRefs = spec.groundedFactRefs or context.factRefs,
    })
    if not realization then return nil end
    realization.responsePlan, realization.offerIDs = filteredPlan(
        realization.responsePlan,
        context
    )
    return realization
end

return Reactions
