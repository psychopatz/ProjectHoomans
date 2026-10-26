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
local InteractionLifecycle = PNC.Semantics
    and PNC.Semantics.InteractionLifecycle or nil
if type(InteractionLifecycle) ~= "table" then
    local ok, loaded = pcall(
        require,
        "PNC/Semantics/PNC_SemanticInteractionLifecycle"
    )
    InteractionLifecycle = ok and loaded or nil
end

local function presentationInteraction(ambientFlavor, context, npcID,
    eventID, eventType)
    local existing = ambientFlavor.interaction
        or context and context.interaction
    if existing then return existing end
    local Envelope = InteractionLifecycle
        and InteractionLifecycle.Envelope or nil
    local playerUUID = H.PlayerUUID and H.PlayerUUID() or nil
    if not Envelope or type(Envelope.NPCSpeech) ~= "function"
        or not playerUUID
        or not ambientFlavor.responsePlanID
        or not ambientFlavor.realizationID
    then
        -- Flavor-only compatibility packets remain presentation/transport
        -- data. Never manufacture semantic provenance after their selection.
        return nil
    end
    return Envelope.NPCSpeech({
        npcID = npcID,
        targetID = playerUUID,
        playerUUID = playerUUID,
        act = ambientFlavor.act or "REACT",
        topic = ambientFlavor.topic or eventType,
        beatID = ambientFlavor.beatID
            or "beat:" .. tostring(eventType) .. ":"
                .. tostring(ambientFlavor.eventRef or eventID),
        responsePlanID = ambientFlavor.responsePlanID,
        flowID = ambientFlavor.flowID
            or "social:" .. tostring(eventType),
        poolID = ambientFlavor.poolID
            or ambientFlavor.responsePlanID
            or ambientFlavor.flavorID,
        realizationFamily = ambientFlavor.realizationFamily,
        realizationID = ambientFlavor.realizationID,
        offerIDs = ambientFlavor.offerIDs
            or context and context.offerIDs,
        eventType = eventType,
        eventRef = ambientFlavor.eventRef or eventID,
        factRefs = ambientFlavor.factRefs or context and context.factRefs,
    })
end

local function boundedList(value, limit)
    local output = {}
    if type(value) ~= "table" then return output end
    for index = 1, math.min(#value, limit or 8) do
        if value[index] ~= nil then
            output[#output + 1] = tostring(value[index])
        end
    end
    return output
end

-- A delivered server event may arrive while the existing conversation view is
-- already open. Project the same bounded lifecycle capsule into that view so
-- Suggestions can expose the server-authorized offers immediately. The
-- server persistence projection remains authoritative on the next request;
-- this is only the existing client session projection, never a second store.
local function projectEventIntoConversation(receive)
    local view = receive.view
    local ambientFlavor = receive.ambientFlavor
    local context = receive.context
    local eventRef = tostring(
        ambientFlavor.eventRef or receive.eventID or ""
    )
    if not view or not view.spec or not view.spec.context
        or eventRef == ""
        or not ambientFlavor.responsePlanID
        or not ambientFlavor.realizationID
    then
        return
    end
    local root = view.spec.context
    local session = view.session
    local lifecycle = session and session.semanticInteractionLifecycle
        or root.interactionLifecycle
    if type(lifecycle) ~= "table" then
        lifecycle = {
            schema = "semantic.interaction.lifecycle.v1",
            status = "ACTIVE",
            topic = ambientFlavor.topic or receive.eventType,
        }
    end
    lifecycle.status = lifecycle.status or "ACTIVE"
    lifecycle.topic = ambientFlavor.topic or receive.eventType
    lifecycle.activeBeat = {
        id = ambientFlavor.beatID
            or "beat:" .. tostring(receive.eventType) .. ":" .. eventRef,
        topic = lifecycle.topic,
        act = ambientFlavor.act or "REACT",
        eventRef = eventRef,
        eventType = receive.eventType,
        responsePlanID = ambientFlavor.responsePlanID,
        flowID = ambientFlavor.flowID,
        poolID = ambientFlavor.poolID
            or ambientFlavor.responsePlanID,
        realizationID = ambientFlavor.realizationID,
        factRefs = boundedList(
            ambientFlavor.factRefs or context.factRefs,
            8
        ),
        offerIDs = boundedList(
            ambientFlavor.offerIDs or context.offerIDs,
            8
        ),
    }
    root.interactionLifecycle = lifecycle
    root.semanticEventFacts = context.semanticEventFacts
    if type(root.conversationBlockContext) == "table" then
        root.conversationBlockContext.interactionLifecycle = lifecycle
        root.conversationBlockContext.semanticEventFacts =
            context.semanticEventFacts
    end
    if session then session.semanticInteractionLifecycle = lifecycle end
end

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
    context.identitySeed = context.identitySeed
        or ambientFlavor.identitySeed
        or summary and summary.identitySeed
        or summary and summary.identitySummary
            and summary.identitySummary.identitySeed
        or npcID
    context.saveSeed = context.saveSeed
        or ambientFlavor.saveSeed
        or summary and summary.saveSeed
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
    context.interaction = context.interaction
        or ambientFlavor.interaction
        or presentationInteraction(
            ambientFlavor,
            context,
            npcID,
            receive.eventID,
            receive.eventType
        )
    context.act = context.act or ambientFlavor.act
    context.topic = context.topic or ambientFlavor.topic
    context.responsePlanID = context.responsePlanID
        or ambientFlavor.responsePlanID
    context.realizationFamily = context.realizationFamily
        or ambientFlavor.realizationFamily
    context.realizationID = context.realizationID
        or ambientFlavor.realizationID
    context.factRefs = context.factRefs or ambientFlavor.factRefs
    context.offerIDs = context.offerIDs or ambientFlavor.offerIDs
    context.eventRef = context.eventRef
        or ambientFlavor.eventRef or receive.eventID
    context.offerIDs = context.offerIDs or ambientFlavor.offerIDs
    context.semanticEventFacts = context.semanticEventFacts
        or ambientFlavor.semanticEventFacts
    projectEventIntoConversation(receive)
    ambientFlavor.interaction = ambientFlavor.interaction
        or context.interaction
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
