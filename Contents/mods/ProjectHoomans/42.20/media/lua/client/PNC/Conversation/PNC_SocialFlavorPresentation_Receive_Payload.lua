-- Queue payload projection for ambient social flavor delivery.

PNC = PNC or {}
PNC.SocialFlavorPresentation = PNC.SocialFlavorPresentation or {}
PNC.SocialFlavorPresentationInternal =
    PNC.SocialFlavorPresentationInternal or {}

local Presentation = PNC.SocialFlavorPresentation
local H = PNC.SocialFlavorPresentationInternal

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
    return {
        eventID = receive.eventID,
        eventRef = ambientFlavor.eventRef or receive.eventID,
        flavorID = ambientFlavor.flavorID
            or "social.witnessed_player_kill",
        family = receive.family,
        priority = tonumber(ambientFlavor.priority) or 35,
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
                false
            ),
            tts = H.FirstBoolean(presentationOverrides.tts, true),
        },
        source = {
            kind = H.Clean(sourceOverrides.kind, "social_flavor"),
            channel = H.Clean(sourceOverrides.channel, nil),
            eventType = H.Clean(sourceOverrides.eventType, receive.eventType),
            relationshipState = receive.relationshipState,
            socialRole = receive.role,
            act = ambientFlavor.act,
            topic = ambientFlavor.topic,
            responsePlanID = ambientFlavor.responsePlanID,
            realizationFamily = ambientFlavor.realizationFamily,
            realizationID = ambientFlavor.realizationID,
            factRefs = ambientFlavor.factRefs,
            contextEligible = sourceOverrides.contextEligible,
            semanticOwned = semanticOwned,
        },
        ttlMs = ambientFlavor.ttlMs,
        holdMs = ambientFlavor.holdMs,
    }
end

return Presentation
