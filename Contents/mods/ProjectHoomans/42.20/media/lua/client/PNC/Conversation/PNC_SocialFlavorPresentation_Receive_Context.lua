-- Context normalization and identity enrichment for ambient social flavor.

PNC = PNC or {}
PNC.SocialFlavorPresentation = PNC.SocialFlavorPresentation or {}
PNC.SocialFlavorPresentationInternal =
    PNC.SocialFlavorPresentationInternal or {}

local Presentation = PNC.SocialFlavorPresentation
local H = PNC.SocialFlavorPresentationInternal
local FlavorAddress = PNC.FlavorAddress
local clean = H.Clean
local firstBoolean = H.FirstBoolean
local currentPlayer = H.CurrentPlayer
local updateMedicalSupplyRequest = H.UpdateMedicalSupplyRequest
local playerAddress = H.PlayerAddress
local npcIdentity = H.NPCIdentity

function H.BuildReceiveContext(ambientFlavor, summary, networkArgs)
    if type(ambientFlavor) ~= "table" then
        return nil, "invalid_flavor"
    end
    local presentationOverrides = type(ambientFlavor.presentationState)
        == "table" and ambientFlavor.presentationState or {}
    local sourceOverrides = type(ambientFlavor.source) == "table"
        and ambientFlavor.source or {}
    local npcID = clean(
        ambientFlavor.npcID
            or networkArgs and networkArgs.npcID
            or summary and summary.npcID,
        nil
    )
    local eventID = clean(
        ambientFlavor.eventID
            or networkArgs and networkArgs.eventID,
        nil
    )
    if not npcID or not eventID then
        return nil, "identity_required"
    end
    local role = clean(
        ambientFlavor.socialRole or ambientFlavor.npcType,
        "neutral"
    )
    local before = networkArgs and (
        networkArgs.relationshipBefore or networkArgs.before
    ) or nil
    local relationshipState = clean(
        ambientFlavor.relationshipState
            or before and (before.state or before.category)
            or summary and (summary.state or summary.category),
        "unknown"
    )
    local relationshipTier = clean(
        ambientFlavor.relationshipTier,
        "reserved"
    )
    local eventType = ambientFlavor.eventType or "social_flavor"
    local family = ambientFlavor.family or "combat_commentary"
    local active, view = H.ActiveConversationFor(npcID)
    local context = type(ambientFlavor.context) == "table"
        and ambientFlavor.context or {}
    return {
        ambientFlavor = ambientFlavor,
        summary = summary,
        networkArgs = networkArgs,
        presentationOverrides = presentationOverrides,
        sourceOverrides = sourceOverrides,
        npcID = npcID,
        eventID = eventID,
        role = role,
        before = before,
        relationshipState = relationshipState,
        relationshipTier = relationshipTier,
        eventType = eventType,
        family = family,
        active = active,
        view = view,
        context = context,
    }
end

function H.EnrichReceiveContext(receive)
    local ambientFlavor = receive.ambientFlavor
    local networkArgs = receive.networkArgs
    local npcID = receive.npcID
    local role = receive.role
    local context = receive.context
    updateMedicalSupplyRequest(npcID, context)
    local speaker = npcIdentity(npcID)
    local player = playerAddress(npcID, currentPlayer(), {
        playerNameKnown = firstBoolean(
            networkArgs and networkArgs.playerNameKnown,
            ambientFlavor.playerNameKnown
        ),
        playerIsFemale = firstBoolean(
            networkArgs and networkArgs.playerIsFemale,
            ambientFlavor.playerIsFemale
        ),
    })
    local victimID = clean(
        ambientFlavor.victimNPCID or context.victimNPCID,
        nil
    )
    local victim = victimID
        and npcIdentity(victimID, "your teammate") or nil
    context.npcType = context.npcType or role
    context.socialRole = context.socialRole or role
    context.relationshipState = context.relationshipState
        or receive.relationshipState
    context.relationshipTier = context.relationshipTier
        or receive.relationshipTier
    -- Downed distress lines may address the attacker by name. The server
    -- sends the authoritative display name; use a neutral noun as fallback.
    if context.downedAttackerName == nil then
        local attackerKind = clean(context.downedThreat, nil)
        context.downedAttackerName = attackerKind == "player"
            and (networkArgs and networkArgs.attackerUsername or nil)
            or nil
    end
    if clean(context.downedAttackerName, nil) == nil
        and clean(context.downedThreat, nil) ~= nil
    then
        context.attackerName = "you"
    else
        context.attackerName = clean(context.downedAttackerName, "you")
    end
    if context.downedNeed ~= nil or context.downedAudience ~= nil then
        context.downedAudience = context.downedAudience or role
        context.downedThreat = context.downedThreat or "unknown"
        context.downedNeed = context.downedNeed or "help"
    end
    local voiceGateway = PNC.VoiceGateway
    if not context.voiceBinding
        and voiceGateway
        and type(voiceGateway.GetNPCBinding) == "function"
    then
        local ok, binding = pcall(voiceGateway.GetNPCBinding, npcID)
        if ok and type(binding) == "table" then
            context.voiceBinding = binding
        end
    end
    context.name = speaker.addressName
    context.firstName = speaker.firstName
    context.surname = speaker.surname
    context.lastName = speaker.lastName
    context.speakerFullName = speaker.fullName
    context.speakerFirstName = speaker.firstName
    context.speakerSurname = speaker.surname
    context.speakerLastName = speaker.lastName
    context.player = player.addressName
    context.playerName = player.addressName
    context.playerAddressName = player.addressName
    context.playerFullName = player.fullName
    context.playerFirstName = player.firstName
    context.playerSurname = player.surname
    context.playerLastName = player.lastName
    context.playerNameKnown = player.known
    context.playerIsFemale = player.isFemale
    context.playerNicknameID = player.nicknameID
    context.npcIdentitySeed = context.npcIdentitySeed
        or FlavorAddress.ResolveNPCSeed(
            PNC.Network and PNC.Network.ClientState
                and PNC.Network.ClientState.snapshots
                and PNC.Network.ClientState.snapshots[npcID],
            npcID
        )
    if victim then
        context.victimNPCID = victimID
        context.victim = victim.addressName
        context.victimName = victim.addressName
        context.victimFullName = victim.fullName
        context.victimFirstName = victim.firstName
        context.victimSurname = victim.surname
        context.victimLastName = victim.lastName
    end
    context.count = 1
    receive.speaker = speaker
    receive.player = player
    return receive
end

return Presentation
