-- Queue payload projection for selected semantic speech delivery.

PNC = PNC or {}
PNC.SemanticSpeechPresentation = PNC.SemanticSpeechPresentation or {}
PNC.SemanticSpeechPresentationInternal =
    PNC.SemanticSpeechPresentationInternal or {}

local Presentation = PNC.SemanticSpeechPresentation
local H = PNC.SemanticSpeechPresentationInternal

function H.BuildReceivePayload(receive)
    local ambientFlavor = receive.ambientFlavor
    local sourceOverrides = receive.sourceOverrides
    local presentationOverrides = receive.presentationOverrides
    local context = receive.context
    local speaker = receive.speaker
    local semanticOwned = ambientFlavor.semanticOwned == true
        or sourceOverrides.kind == "semantic_speech"
        or ambientFlavor.responsePlanID ~= nil
        or ambientFlavor.realizationID ~= nil
    local selectedText = type(ambientFlavor.text) == "string"
        and ambientFlavor.text
        or type(ambientFlavor.resolvedText) == "string"
            and ambientFlavor.resolvedText
            or nil
    local sceneID = H.Clean(ambientFlavor.sceneID or context.sceneID, nil)
    local lane = H.Clean(
        ambientFlavor.lane or context.lane or sourceOverrides.lane,
        sceneID and "scene" or "beat"
    )
    local threadID = lane == "beat"
        and H.Clean(ambientFlavor.threadID or context.threadID, nil)
        or nil
    local conversationID = H.Clean(
        ambientFlavor.conversationID or context.conversationID,
        lane == "scene" and sceneID or nil
    )
    local priority = tonumber(ambientFlavor.priority)
        or (lane == "scene" and 80 or 35)
    return {
        eventID = receive.eventID,
        eventRef = ambientFlavor.eventRef or receive.eventID,
        -- PsychopatzCore's queue retains this transport field for external
        -- adopters; its value is already-selected semantic speech identity.
        flavorID = ambientFlavor.speechEventID
            or ambientFlavor.flavorID
            or "semantic.speech.selected",
        family = receive.family,
        lane = lane,
        sceneID = sceneID,
        threadID = threadID,
        conversationID = conversationID,
        priority = priority,
        llmPriority = tonumber(ambientFlavor.llmPriority) or 90,
        weight = tonumber(ambientFlavor.weight) or 1,
        -- Semantic producers historically called this field `resolvedText`.
        -- Normalize it here so the presentation queue receives the already
        -- selected wording and never has to resolve meaning again.
        text = selectedText,
        semanticOwned = semanticOwned,
        act = ambientFlavor.act,
        topic = ambientFlavor.topic,
        responsePlanID = ambientFlavor.responsePlanID,
        poolID = ambientFlavor.poolID,
        realizationFamily = ambientFlavor.realizationFamily,
        realizationID = ambientFlavor.realizationID,
        contentOwner = ambientFlavor.contentOwner,
        factRefs = ambientFlavor.factRefs,
        offerIDs = ambientFlavor.offerIDs or context.offerIDs,
        speakerID = receive.npcID,
        speakerName = speaker.fullName,
        playerUUID = H.PlayerUUID(),
        voiceBinding = context.voiceBinding,
        npcType = receive.role,
        socialRole = receive.role,
        relationshipState = receive.relationshipState,
        relationshipTier = receive.relationshipTier,
        context = context,
        interaction = ambientFlavor.interaction
            or context.interaction,
        seed = receive.eventID,
        mergeKey = ambientFlavor.mergeKey
            or receive.npcID .. ":" .. tostring(ambientFlavor.family or "ambient"),
        llmEligible = ambientFlavor.llmEligible ~= false,
        memoryEligible = ambientFlavor.memoryEligible == true,
        llmGraceMs = tonumber(ambientFlavor.llmGraceMs) or 2500,
        cooldowns = ambientFlavor.cooldowns,
        presentationState = {
            nameplate = H.FirstBoolean(
                presentationOverrides.nameplate,
                not receive.active
            ),
            conversationUI = H.FirstBoolean(
                presentationOverrides.conversationUI,
                receive.active
            ),
            interrupt = H.FirstBoolean(
                presentationOverrides.interrupt,
                ambientFlavor.interrupt == true
            ),
            tts = H.FirstBoolean(presentationOverrides.tts, true),
        },
        interrupt = ambientFlavor.interrupt == true,
        source = {
            kind = H.Clean(sourceOverrides.kind, "social_flavor"),
            channel = H.Clean(sourceOverrides.channel, nil),
            lane = lane,
            sceneID = sceneID,
            threadID = threadID,
            sessionID = H.Clean(sourceOverrides.sessionID, sceneID),
            priority = priority,
            eventType = H.Clean(sourceOverrides.eventType, receive.eventType),
            relationshipState = receive.relationshipState,
            socialRole = receive.role,
            act = ambientFlavor.act,
            topic = ambientFlavor.topic,
            responsePlanID = ambientFlavor.responsePlanID,
            realizationFamily = ambientFlavor.realizationFamily,
            realizationID = ambientFlavor.realizationID,
            contentOwner = ambientFlavor.contentOwner,
            factRefs = ambientFlavor.factRefs,
            contextEligible = sourceOverrides.contextEligible,
            semanticOwned = semanticOwned,
        },
        ttlMs = ambientFlavor.ttlMs,
        holdMs = ambientFlavor.holdMs,
    }
end

return Presentation
