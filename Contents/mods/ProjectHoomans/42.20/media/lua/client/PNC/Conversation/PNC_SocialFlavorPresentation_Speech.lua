-- Client-side player-speech and safety presentation provider.

PNC = PNC or {}
PNC.SocialFlavorPresentation = PNC.SocialFlavorPresentation or {}
PNC.SocialFlavorPresentationInternal =
    PNC.SocialFlavorPresentationInternal or {}

local Presentation = PNC.SocialFlavorPresentation
local H = PNC.SocialFlavorPresentationInternal
local Client = PsychopatzCore.SocialFlavorClient
local FlavorAddress = PNC.FlavorAddress
local Targets = PNC.CompanionTargetResolver
local clean = H.Clean
local currentPlayer = H.CurrentPlayer
local currentTime = H.CurrentTime
local playerUUID = H.PlayerUUID
local playerAddress = H.PlayerAddress
local npcIdentity = H.NPCIdentity
local activeConversationFor = H.ActiveConversationFor
local MAX_PLAYER_SPEECH_RECIPIENTS = 8

require "PNC/Conversation/PNC_SocialFlavorPresentation_Receive"

local function speechTargets(player, context)
    local explicit = type(context) == "table" and context.targets or nil
    if type(explicit) == "table" and #explicit > 0 then
        return explicit
    end
    if type(context) == "table" and context.target then
        return { context.target }
    end
    if Targets and Targets.CollectOwnedCompanions then
        return Targets.CollectOwnedCompanions(player)
    end
    return {}
end

local function speechTargetID(target)
    return clean(target and (
        target.id or target.npcID or target.npcUUID
            or target.source and target.source.id
    ), nil)
end

-- Player speech reactions stay entirely on the receiving client.  This is
-- intentionally separate from Receive(), which consumes server-authoritative
-- social events.  The server never receives or generates this flavor text.
function Presentation.ReceivePlayerSpeech(player, text, sourceContext)
    text = clean(text, "")
    if text == "" or not player then return false end
    text = string.sub(text, 1, Client.MAX_TEXT_LENGTH or 420)
    local context = type(sourceContext) == "table" and sourceContext or {}
    local targets = speechTargets(player, context)
    local playerIDValue = playerUUID()
    if not playerIDValue then
        playerIDValue = "local-player"
    end
    local accepted = 0
    local nowValue = PNC.Core and PNC.Core.Now and PNC.Core.Now()
        or getTimeInMillis and getTimeInMillis() or 0
    local index
    for index = 1, math.min(#targets, MAX_PLAYER_SPEECH_RECIPIENTS) do
        local target = targets[index]
        local npcID = speechTargetID(target)
        if npcID then
            local active = activeConversationFor(npcID)
            local speaker = npcIdentity(npcID, target.name)
            local playerIdentityValue = playerAddress(npcID, player)
            local eventID = "player-speech:" .. tostring(playerIDValue)
                .. ":" .. tostring(nowValue) .. ":" .. tostring(index)
            local targetContext = {
                eventType = "player_spoke",
                playerMessage = text,
                npcID = npcID,
                socialRole = clean(
                    target.socialRole or target.npcType
                        or target.source and (
                            target.source.socialRole or target.source.npcType
                        ),
                    "colonist"
                ),
                speakerFullName = speaker.fullName,
                speakerFirstName = speaker.firstName,
                speakerSurname = speaker.surname,
                npcIdentitySeed = FlavorAddress.ResolveNPCSeed(
                    target.source or target, npcID
                ),
                player = playerIdentityValue.addressName,
                playerName = playerIdentityValue.addressName,
                playerAddressName = playerIdentityValue.addressName,
                playerFullName = playerIdentityValue.fullName,
                playerFirstName = playerIdentityValue.firstName,
                playerSurname = playerIdentityValue.surname,
                playerLastName = playerIdentityValue.lastName,
                playerNameKnown = playerIdentityValue.known,
                playerIsFemale = playerIdentityValue.isFemale,
                playerNicknameID = playerIdentityValue.nicknameID,
                speechScope = "owned_colonists",
                sourceCommandID = context.commandID,
            }
            local ok = Client.Enqueue({
                eventID = eventID,
                flavorID = "social.player_spoke",
                family = "player_speech_reaction",
                priority = 35,
                llmPriority = 90,
                weight = 1,
                speakerID = npcID,
                speakerName = speaker.fullName,
                playerUUID = playerIDValue,
                context = targetContext,
                seed = eventID,
                llmEligible = true,
                memoryEligible = false,
                llmGraceMs = 2500,
                cooldowns = {
                    ambientMs = 2500,
                    familyMs = 8000,
                    speakerMs = 8000,
                    mergeWindowMs = 2500,
                },
                mergeKey = "player-speech:" .. npcID,
                presentationState = {
                    nameplate = not active,
                    conversationUI = active,
                    interrupt = false,
                    tts = true,
                },
                source = {
                    kind = "social_flavor",
                    channel = "player_speech",
                    eventType = "player_spoke",
                    contextEligible = false,
                    speechScope = "owned_colonists",
                },
            })
            if ok == true then accepted = accepted + 1 end
        end
    end
    return accepted > 0
end

-- A safety interruption is still authored social speech.  Queue it through
-- Core so the same resolved line can reach conversation history, the diary,
-- and the shared voice stream before the UI finishes its closing animation.
function Presentation.EnqueueConversationSafety(spec, state, reason)
    local context = spec and spec.context or {}
    local entry = context.entry or {}
    local npcID = clean(
        state and state.npcID or spec and spec.npcID or entry.id,
        nil
    )
    local player = context.player or currentPlayer()
    local identity = playerAddress(npcID, player)
    local role
    local speaker
    local eventID
    local safetyContext
    local accepted
    local enqueueReason
    if tostring(reason or "") ~= "danger" then
        return false, "not_danger"
    end
    if not npcID then return false, "identity_required" end
    if state and state.safetyFeedbackShown == true then
        return false, "already_presented"
    end
    if state then state.safetyFeedbackShown = true end
    role = clean(
        context.socialRole or context.npcType
            or entry.socialRole or entry.npcType,
        "neutral"
    )
    speaker = npcIdentity(npcID, "Companion")
    eventID = "conversation-safety:" .. npcID .. ":"
        .. tostring(state and state.token or currentTime())
    safetyContext = {
        eventType = "conversation_safety",
        reason = "danger",
        npcID = npcID,
        npcType = role,
        socialRole = role,
        player = identity.addressName,
        playerName = identity.addressName,
        playerAddressName = identity.addressName,
        playerFullName = identity.fullName,
        playerFirstName = identity.firstName,
        playerSurname = identity.surname,
        playerLastName = identity.lastName,
        playerNameKnown = identity.known,
        playerIsFemale = identity.isFemale,
        playerNicknameID = identity.nicknameID,
        npcIdentitySeed = FlavorAddress.ResolveNPCSeed(entry, npcID),
        speakerFullName = speaker.fullName,
        speakerFirstName = speaker.firstName,
        speakerSurname = speaker.surname,
        relationshipState = context.relationshipState,
        relationshipTier = context.relationshipTier,
    }
    accepted, enqueueReason = Client.Enqueue({
        eventID = eventID,
        flavorID = "social.conversation_safety_danger",
        family = "conversation_safety",
        priority = Client.CRITICAL_PRIORITY or 100,
        -- Safety speech must win over ordinary ambient commentary, even when
        -- another flavor is already occupying the presentation lane.
        weight = 1000,
        speakerID = npcID,
        speakerName = speaker.fullName,
        playerUUID = playerUUID() or identity.addressName,
        npcType = role,
        socialRole = role,
        relationshipState = context.relationshipState,
        relationshipTier = context.relationshipTier,
        context = safetyContext,
        seed = state and state.token or eventID,
        llmEligible = false,
        memoryEligible = false,
        cooldowns = {
            familyMs = 0,
            speakerMs = 0,
            ambientMs = 0,
        },
        presentationState = {
            -- The full conversation view may already be closing (or may have
            -- been rejected before its session was created).  Keep this
            -- visible in the detached nameplate speech lane as well.
            nameplate = true,
            conversationUI = true,
            interrupt = true,
            tts = true,
        },
        source = {
            kind = "social_flavor",
            channel = "conversation_safety",
            eventType = "conversation_safety",
            reason = "danger",
            contextEligible = false,
        },
        ttlMs = 4000,
        holdMs = 1500,
    })
    if accepted ~= true then return false, enqueueReason end
    if type(Client.Pump) == "function" then
        local delivered, deliveryReason = Client.Pump(currentTime())
        return delivered == true, deliveryReason or enqueueReason
    end
    return true, enqueueReason
end

return Presentation
