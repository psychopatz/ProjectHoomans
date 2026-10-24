-- Compact results for authority-owned vanilla emote interactions.

local Network = PNC.Network
local Core = PNC.Core
local Const = PNC.Const
local Presentation = PNC.RelationshipPresentation
local InteractionLifecycle = PNC.Semantics
    and PNC.Semantics.InteractionLifecycle or nil

local function interactionFactRefs(context, ambient)
    local refs = {}
    local ambientContext = ambient and ambient.context or nil
    local memoryID = context.memoryID or ambientContext
        and ambientContext.memoryID
    if memoryID then refs[#refs + 1] = memoryID end
    local memoryType = context.memoryType or ambientContext
        and ambientContext.memoryType
    if memoryType then refs[#refs + 1] = memoryType end
    return refs
end

local function ensureNPCSpeechInteraction(
    targetPlayer, npcID, reason, context
)
    local ambient = context.ambientFlavor
    local existing = context.interaction
        or type(ambient) == "table" and ambient.interaction or nil
    if existing then return existing end
    if context.source == "proximity_greeting"
        or reason == "proximity_greeting"
    then
        return nil
    end
    if not isServer or not isServer() then return nil end
    if not PNC.Conversation
        or not PNC.Conversation.InteractionLifecyclePersistence
    then
        pcall(require, "PNC/Conversation/PNC_InteractionLifecyclePersistence")
    end
    if not InteractionLifecycle then
        pcall(require, "PNC/Semantics/PNC_SemanticInteractionLifecycle")
        InteractionLifecycle = PNC.Semantics
            and PNC.Semantics.InteractionLifecycle or nil
    end
    local persistence = PNC.Conversation
        and PNC.Conversation.InteractionLifecyclePersistence or nil
    local envelopeBuilder = InteractionLifecycle
        and InteractionLifecycle.Envelope or nil
    if not persistence or type(persistence.RecordNPCSpeech) ~= "function"
        or type(envelopeBuilder) ~= "table"
        or type(envelopeBuilder.NPCSpeech) ~= "function"
        or not PNC.PlayerCharacters
        or type(PNC.PlayerCharacters.GetEntityKey) ~= "function"
    then
        return nil
    end
    local playerKey = PNC.PlayerCharacters.GetEntityKey(targetPlayer, {
        callback = "relationship_presentation_interaction",
        worldAgeHours = context.worldAgeHours,
    })
    if not playerKey then return nil end
    local eventID = context.eventID or context.eventRef
    if not eventID then return nil end
    local eventType = context.eventType or reason or "social_reaction"
    local beatID = "beat:" .. tostring(eventType) .. ":"
        .. tostring(eventID)
    local envelope = envelopeBuilder.NPCSpeech({
        npcID = npcID,
        targetID = playerKey,
        playerUUID = playerKey,
        act = context.act or "REACT",
        topic = context.topic or eventType,
        beatID = context.beatID or beatID,
        responsePlanID = context.responsePlanID
            or "social.reaction." .. tostring(eventType),
        eventType = eventType,
        eventRef = eventID,
        flowID = context.flowID or "social:" .. tostring(eventType),
        poolID = ambient and ambient.flavorID,
        factRefs = interactionFactRefs(context, ambient),
        worldHour = context.worldAgeHours,
    })
    if not envelope then return nil end
    local recorded = persistence.RecordNPCSpeech({
        npcID = npcID,
        targetID = playerKey,
        playerUUID = playerKey,
        act = context.act or "REACT",
        topic = context.topic or eventType,
        beatID = context.beatID or beatID,
        responsePlanID = context.responsePlanID
            or "social.reaction." .. tostring(eventType),
        eventType = eventType,
        eventRef = eventID,
        flowID = context.flowID or "social:" .. tostring(eventType),
        poolID = ambient and ambient.flavorID,
        factRefs = interactionFactRefs(context, ambient),
        expectedReplies = context.expectedReplies,
        worldHour = context.worldAgeHours,
        meaningful = true,
    })
    if not recorded then return nil end
    context.interaction = envelope
    if type(ambient) == "table" then ambient.interaction = envelope end
    return envelope
end

function Network.SendPlayerEmoteInteractionResult(targetPlayer, result)
    local payload = type(result) == "table" and result or {}
    payload.serverTime = Core.Now()
    if isServer and isServer() and targetPlayer and sendServerCommand then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_PLAYER_EMOTE_INTERACTION_RESULT,
            payload
        )
        return true
    end
    return false
end

-- Ambient NPC speech is addressed only to the player who entered the social
-- radius.  The relationship summary itself still travels through the shared
-- ConversationRelationship transport below.
function Network.SendSocialGreeting(targetPlayer, greeting)
    local payload = type(greeting) == "table" and greeting or {}
    payload.serverTime = Core.Now()
    if isServer and isServer() and targetPlayer and sendServerCommand then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_SOCIAL_GREETING,
            payload
        )
        return true
    elseif not isServer or not isServer() then
        triggerEvent(
            "OnServerCommand",
            Const.MODULE,
            Const.CMD_SOCIAL_GREETING,
            payload
        )
        return true
    end
    return false
end

-- Builds the same player-facing relationship summary used by the conversation
-- request and sends it through Network.SendConversationRelationship.  Callers
-- should use this after an authoritative mutation when they have an NPC id but
-- do not want to recreate presentation formatting locally.
function Network.SendConversationRelationshipForNPC(
    targetPlayer,
    npcID,
    reason,
    relationshipContext
)
    local summary
    local buildReason
    local context = type(relationshipContext) == "table"
        and relationshipContext or {}
    ensureNPCSpeechInteraction(targetPlayer, npcID, reason, context)
    if Presentation and Presentation.BuildForConversation then
        summary, buildReason = Presentation.BuildForConversation(
            targetPlayer,
            npcID
        )
    end
    if not summary then
        return false, buildReason or "relationship_presentation_unavailable"
    end
    context.npcID = tostring(npcID or summary.npcID or "")
    context.relationshipAfter = summary
    local sent = Network.SendConversationRelationship(
        targetPlayer,
        summary,
        reason or "relationship_changed",
        context
    )
    return sent == true, sent and nil or "relationship_transport_unavailable",
        summary
end

return Network
