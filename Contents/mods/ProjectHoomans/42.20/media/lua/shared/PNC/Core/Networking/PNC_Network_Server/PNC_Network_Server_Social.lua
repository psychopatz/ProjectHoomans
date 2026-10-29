-- Compact results for authority-owned vanilla emote interactions.

local Network = PNC.Network
local Core = PNC.Core
local Const = PNC.Const
local Presentation = PNC.RelationshipPresentation
local InteractionLifecycle = PNC.Semantics
    and PNC.Semantics.InteractionLifecycle or nil

local function appendUniqueRef(output, seen, value)
    if value == nil then return end
    value = tostring(value)
    if value == "" or seen[value] then return end
    if #output >= 8 then return end
    seen[value] = true
    output[#output + 1] = value
end

local function interactionFactRefs(context, ambient)
    local refs = {}
    local seen = {}
    local ambientContext = ambient and ambient.context or nil
    local function append(value)
        if type(value) == "table" then
            for index = 1, math.min(#value, 8) do
                appendUniqueRef(refs, seen, value[index])
            end
        else
            appendUniqueRef(refs, seen, value)
        end
    end
    append(context.factRefs)
    append(ambient and ambient.factRefs)
    append(ambientContext and ambientContext.factRefs)
    append(context.memoryID or ambientContext and ambientContext.memoryID)
    append(context.memoryType or ambientContext and ambientContext.memoryType)
    return refs
end

local function responseCatalog()
    local catalog = PNC.Semantics and PNC.Semantics.ResponseCatalog
    if type(catalog) == "table"
        and type(catalog.OffersForSelection) == "function"
    then
        return catalog
    end
    local ok, loaded = pcall(
        require, "PNC/Semantics/PNC_SemanticDialogueResponseCatalog"
    )
    if ok and type(loaded) == "table"
        and type(loaded.OffersForSelection) == "function"
    then
        return loaded
    end
    return nil
end

local function semanticOfferIDs(context, ambient)
    local output = {}
    local seen = {}
    local explicit = context.offerIDs
        or ambient and ambient.offerIDs
    if type(explicit) == "table" then
        for index = 1, math.min(#explicit, 8) do
            appendUniqueRef(output, seen, explicit[index])
        end
        return output
    end
    local responsePlanID = context.responsePlanID
        or ambient and ambient.responsePlanID
    local realizationID = context.realizationID
        or ambient and ambient.realizationID
    if not responsePlanID or not realizationID then return output end
    local poolID = context.poolID
        or ambient and ambient.poolID
        or responsePlanID
    local catalog = responseCatalog()
    if not catalog then return output end
    for _, offer in ipairs(
        catalog.OffersForSelection(poolID, realizationID) or {}
    ) do
        appendUniqueRef(output, seen, offer and offer.id)
    end
    return output
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
    local responsePlanID = context.responsePlanID
        or ambient and ambient.responsePlanID
        or "social.reaction." .. tostring(eventType)
    local realizationID = context.realizationID
        or ambient and ambient.realizationID
    local poolID = context.poolID
        or ambient and ambient.poolID
        or realizationID and responsePlanID
        or ambient and ambient.speechEventID
    local realizationFamily = context.realizationFamily
        or ambient and ambient.realizationFamily
    local factRefs = interactionFactRefs(context, ambient)
    local offerIDs = semanticOfferIDs(context, ambient)
    local envelope = envelopeBuilder.NPCSpeech({
        npcID = npcID,
        targetID = playerKey,
        playerUUID = playerKey,
        act = context.act or "REACT",
        topic = context.topic or eventType,
        beatID = context.beatID or beatID,
        responsePlanID = responsePlanID,
        eventType = eventType,
        eventRef = eventID,
        flowID = context.flowID or "social:" .. tostring(eventType),
        poolID = poolID,
        realizationFamily = realizationFamily,
        realizationID = realizationID,
        offerIDs = offerIDs,
        factRefs = factRefs,
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
        responsePlanID = responsePlanID,
        eventType = eventType,
        eventRef = eventID,
        flowID = context.flowID or "social:" .. tostring(eventType),
        poolID = poolID,
        realizationFamily = realizationFamily,
        realizationID = realizationID,
        offerIDs = offerIDs,
        factRefs = factRefs,
        expectedReplies = context.expectedReplies,
        worldHour = context.worldAgeHours,
        meaningful = context.meaningful ~= false,
        transient = context.transientInteraction == true,
        ttlHours = context.interactionTTLHours,
    })
    if not recorded then return nil end
    context.interaction = envelope
    context.offerIDs = offerIDs
    context.factRefs = factRefs
    if type(ambient) == "table" then
        ambient.interaction = envelope
        ambient.offerIDs = offerIDs
        ambient.factRefs = factRefs
    end
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

-- Runtime-only invalidation/state projection for the active tactical combat
-- prompt. This transports authority state only; it never owns the encounter
-- decision or semantic choice.
function Network.SendCombatEncounterIntentState(targetPlayer, payload)
    payload = type(payload) == "table" and payload or {}
    payload.serverTime = Core and Core.Now and Core.Now() or payload.serverTime
    if isServer and isServer() and targetPlayer and sendServerCommand then
        sendServerCommand(
            targetPlayer,
            Const.MODULE,
            Const.CMD_COMBAT_ENCOUNTER_INTENT_STATE,
            payload
        )
        return true
    elseif not isServer or not isServer() then
        if type(triggerEvent) == "function" then
            triggerEvent(
                "OnServerCommand",
                Const.MODULE,
                Const.CMD_COMBAT_ENCOUNTER_INTENT_STATE,
                payload
            )
            return true
        end
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
