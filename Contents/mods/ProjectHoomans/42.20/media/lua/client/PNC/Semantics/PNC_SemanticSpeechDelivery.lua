-- One delivery seam for already-selected semantic NPC speech.
--
-- Semantic authorities choose the realization and provide resolved text. This
-- adapter only routes that result to the active Conversation session or to
-- the existing world speech/nameplate/TTS presentation path.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Delivery = PNC.Semantics.SemanticSpeechDelivery or {}
PNC.Semantics.SemanticSpeechDelivery = Delivery

Delivery.MAX_DEDUPE_EVENTS = 32

local function clean(value, limit)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return nil end
    return string.sub(value, 1, limit or 160)
end

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 5 then return nil end
    local output = {}
    for key, item in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(item, depth + 1)
        end
    end
    return output
end

local function remember(store, eventID)
    if type(store) ~= "table" then return true end
    local key = clean(eventID, 128)
    if not key then return true end
    store.order = type(store.order) == "table" and store.order or {}
    store.seen = type(store.seen) == "table" and store.seen or {}
    if store.seen[key] then return false end
    store.seen[key] = true
    store.order[#store.order + 1] = key
    while #store.order > Delivery.MAX_DEDUPE_EVENTS do
        local oldest = table.remove(store.order, 1)
        store.seen[oldest] = nil
    end
    return true
end

local function messagePayload(options, text)
    return {
        text = text,
        fallback = text,
        key = options.realizationID or options.responsePlanID
            or "semantic_speech",
        responsePlanID = options.responsePlanID,
        realizationFamily = options.realizationFamily,
        realizationID = options.realizationID,
        factRefs = copy(options.factRefs),
        topic = options.topic,
        semanticAct = options.semanticAct,
    }
end

local function messageMetadata(options)
    return {
        speakerID = options.npcID,
        speakerName = options.speakerName,
        npcID = options.npcID,
        source = {
            kind = "semantic_speech",
            channel = options.channel or "semantic_conversation",
            eventType = options.eventType or "semantic_speech",
            semanticAct = options.semanticAct,
            topic = options.topic,
            responsePlanID = options.responsePlanID,
            realizationFamily = options.realizationFamily,
            realizationID = options.realizationID,
            factRefs = copy(options.factRefs),
            contextEligible = false,
            deliveryOwner = options.deliveryOwner,
        },
        provenance = {
            provider = "semantic_realization_authority",
            responsePlanID = options.responsePlanID,
            realizationFamily = options.realizationFamily,
            realizationID = options.realizationID,
            factRefs = copy(options.factRefs),
        },
        interaction = copy(options.interaction),
        eventID = options.eventID,
    }
end

local function activeConversationPresentation()
    local presentation = PNC.Semantics.ConversationSpeechProvider
    if type(presentation) ~= "table" then
        presentation = require
            "PNC/Semantics/PNC_SemanticConversationSpeechProvider"
    end
    return presentation
end

local function deliverSession(options, text)
    local session = options.session
    if not session or type(session.queueMessage) ~= "function" then
        return false, "conversation_session_unavailable"
    end
    session:queueMessage(
        "npc",
        messagePayload(options, text),
        messageMetadata(options)
    )
    return true, "conversation_session", text
end

local function deliverWorld(options, text)
    local presentation = activeConversationPresentation()
    if type(presentation) ~= "table"
        or type(presentation.Receive) ~= "function"
    then
        return false, "semantic_speech_presentation_unavailable"
    end
    local npcID = clean(options.npcID, 96)
    local eventID = clean(options.eventID, 128)
    if not npcID or not eventID then
        return false, "semantic_speech_identity_required"
    end
    local accepted, reason = presentation.Receive({
        eventID = eventID,
        npcID = npcID,
        flavorID = options.compatibilityFlavorID
            or "semantic.speech.selected",
        family = options.family or "semantic_speech",
        priority = tonumber(options.priority) or 100,
        weight = tonumber(options.weight) or 100,
        eventType = options.eventType or "semantic_speech",
        act = options.semanticAct,
        topic = options.topic,
        responsePlanID = options.responsePlanID,
        realizationFamily = options.realizationFamily,
        realizationID = options.realizationID,
        factRefs = copy(options.factRefs),
        text = text,
        interaction = copy(options.interaction),
        source = {
            kind = "semantic_speech",
            channel = options.channel or "semantic_conversation",
            eventType = options.eventType or "semantic_speech",
            semanticAct = options.semanticAct,
            topic = options.topic,
            responsePlanID = options.responsePlanID,
            realizationFamily = options.realizationFamily,
            realizationID = options.realizationID,
            factRefs = copy(options.factRefs),
            contextEligible = false,
            deliveryOwner = options.deliveryOwner,
        },
        presentationState = {
            -- Receive derives Conversation UI ownership from the live Core
            -- view. Nameplate is suppressed for that active speaker and TTS
            -- remains enabled for both sinks.
            tts = options.tts ~= false,
        },
        cooldowns = options.cooldowns or {
            familyMs = 0,
            speakerMs = 0,
            ambientMs = 0,
            mergeWindowMs = 0,
        },
        mergeKey = options.mergeKey,
        ttlMs = options.ttlMs or 15000,
        holdMs = options.holdMs or 1200,
        pumpImmediately = options.pumpImmediately == true,
        context = {
            npcID = npcID,
            target = options.target,
            playerActor = options.playerActor,
            speakerName = options.speakerName,
            eventID = eventID,
            interaction = copy(options.interaction),
            semanticAct = options.semanticAct,
            topic = options.topic,
            responsePlanID = options.responsePlanID,
            realizationFamily = options.realizationFamily,
            realizationID = options.realizationID,
            factRefs = copy(options.factRefs),
            deliveryOwner = options.deliveryOwner,
        },
    }, {
        npcID = npcID,
        eventID = eventID,
    }, {
        npcID = npcID,
        eventID = eventID,
    })
    if accepted == true then
        return true, reason or "queued", text
    end
    return false, reason or "semantic_speech_rejected", text
end

function Delivery.NPC(options)
    options = type(options) == "table" and options or {}
    local text = clean(options.text or options.fallback, 256)
    if not text then return false, "semantic_speech_text_required" end
    if not remember(options.dedupeStore, options.eventID) then
        return false, "duplicate_delivered", text
    end

    local accepted, reason, deliveredText = deliverSession(options, text)
    if accepted == true then
        return true, reason, deliveredText
    end

    accepted, reason, deliveredText = deliverWorld(options, text)
    if accepted == true then
        return true, reason, deliveredText
    end
    return false, reason, deliveredText
end

return Delivery
