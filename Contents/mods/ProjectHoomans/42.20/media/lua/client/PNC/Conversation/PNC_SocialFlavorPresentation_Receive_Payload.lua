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
    return {
        eventID = receive.eventID,
        flavorID = ambientFlavor.flavorID
            or "social.witnessed_player_kill",
        family = receive.family,
        priority = tonumber(ambientFlavor.priority) or 35,
        llmPriority = tonumber(ambientFlavor.llmPriority) or 90,
        weight = tonumber(ambientFlavor.weight) or 1,
        text = type(ambientFlavor.text) == "string"
            and ambientFlavor.text or nil,
        speakerID = receive.npcID,
        speakerName = speaker.fullName,
        playerUUID = H.PlayerUUID(),
        voiceBinding = context.voiceBinding,
        npcType = receive.role,
        socialRole = receive.role,
        relationshipState = receive.relationshipState,
        relationshipTier = receive.relationshipTier,
        context = context,
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
            contextEligible = sourceOverrides.contextEligible,
        },
        ttlMs = ambientFlavor.ttlMs,
        holdMs = ambientFlavor.holdMs,
    }
end

return Presentation
