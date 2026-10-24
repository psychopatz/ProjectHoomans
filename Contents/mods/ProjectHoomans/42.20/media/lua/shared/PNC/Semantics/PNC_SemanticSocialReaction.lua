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

Reactions.VERSION = 1

local function poolFor(spec)
    if spec.poolID then return tostring(spec.poolID) end
    local eventType = string.lower(tostring(spec.eventType or ""))
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
    if string.find(eventType, "combat", 1, true)
        or string.find(eventType, "kill", 1, true)
        or string.find(eventType, "horde", 1, true)
        or string.find(eventType, "zombie", 1, true)
    then
        return "semantic.combat.reaction"
    end
    if string.find(eventType, "follower", 1, true)
        or string.find(eventType, "companion", 1, true)
    then
        return "semantic.companion.reaction"
    end
    return "semantic.social.reaction"
end

function Reactions.Resolve(spec)
    spec = type(spec) == "table" and spec or {}
    local context = type(spec.context) == "table" and spec.context or {}
    local poolID = poolFor(spec)
    return Authority.Resolve({
        poolID = poolID,
        responsePlanID = spec.responsePlanID or poolID,
        realizationFamily = spec.realizationFamily or poolID,
        act = spec.act or "REACT",
        topic = spec.topic or spec.eventType or "social_reaction",
        context = context,
        salt = spec.salt or spec.eventID or spec.npcID,
        groundedFactRefs = spec.groundedFactRefs,
    })
end

return Reactions
