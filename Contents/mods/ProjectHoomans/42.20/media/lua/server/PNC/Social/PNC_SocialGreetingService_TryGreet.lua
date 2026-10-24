if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Server-authoritative social greeting transaction provider.
PNC = PNC or {}
PNC.SocialGreeting = PNC.SocialGreeting or {}
local Service = PNC.SocialGreeting
if not Service.Internal then return Service end
local Internal = Service.Internal
local Relationships = Internal.Relationships
local Interactions = Internal.Interactions
local Meeting = Internal.Meeting
local PresentationAnimations = Internal.PresentationAnimations
local Network = Internal.Network
local worldAgeHours = Internal.WorldAgeHours
local relationshipSummary = Internal.RelationshipSummary
local relationshipDelta = Internal.RelationshipDelta
local effectFor = Internal.EffectFor
local playerKey = Internal.PlayerKey
local InteractionLifecycle = PNC.Semantics
    and PNC.Semantics.InteractionLifecycle or nil
local InteractionPersistence = PNC.Conversation
    and PNC.Conversation.InteractionLifecyclePersistence or nil
local RealizationAuthority = PNC.Semantics
    and PNC.Semantics.RealizationAuthority or nil
if not RealizationAuthority then
    local ok, loaded = pcall(
        require,
        "PNC/Semantics/PNC_SemanticDialogueRealizationAuthority"
    )
    RealizationAuthority = ok and loaded or nil
end
local ContextProviders = PNC.Semantics
    and PNC.Semantics.ContextProviders or nil
if type(ContextProviders) ~= "table" then
    local ok, loaded = pcall(
        require,
        "PNC/Core/Social/PNC_FlavorTextResolver"
    )
    ContextProviders = ok and loaded or nil
end

local function greetingFactRefs(details)
    local refs = {}
    if details and details.memoryID then refs[#refs + 1] = details.memoryID end
    if details and details.memoryType then refs[#refs + 1] = details.memoryType end
    return refs
end

function Service.TryGreet(player, target, at, actorKey)
    local npcID = tostring(target and target.id or "")
    local record = target and target.record or nil
    local relationship
    local npcType
    local tier
    local day
    local eventID
    local definition
    local applied
    local reason
    local details
    local afterRelationship
    local before
    local after
    local delta
    local presentationEventID
    local greetingState
    local flavorID
    local compatibilityFlavorID
    local realization
    local semanticContext
    local beatID
    local meetingOK
    local meetingReason
    if npcID == "" or not record or not player then
        return false, "invalid_target"
    end
    if player.isDead and player:isDead() then
        return false, "player_unavailable"
    end
    if target.meetingEligible == false then
        return false, target.meetingReason or "not_meeting"
    elseif target.meetingEligible ~= true then
        meetingOK, meetingReason = Meeting.CanPlayerMeetNPC(
            player,
            record,
            target.body,
            Service.GREETING_RADIUS
        )
        if not meetingOK then return false, meetingReason end
    end
    actorKey = tostring(actorKey or playerKey(player))
    at = worldAgeHours(at)
    relationship = Relationships and Relationships.Get
        and Relationships.Get(npcID, actorKey) or nil
    npcType = ContextProviders and ContextProviders.ResolveNPCType
        and ContextProviders.ResolveNPCType(record) or "neutral"
    if not Interactions
        or not Interactions.IsAutomaticGreetingEligible
        or not Interactions.IsAutomaticGreetingEligible(
            relationship,
            npcType
        )
    then
        return false, "relationship_not_eligible"
    end
    if Interactions.HasGreetingToday
        and Interactions.HasGreetingToday(relationship, at)
    then
        return false, "already_greeted_today"
    end
    definition = PNC.SocialEventDefinitions
        and PNC.SocialEventDefinitions.npc_proximity_greeting or nil
    if not definition or not Relationships
        or not Relationships.ApplyConversationEffect
    then
        return false, "relationship_service_unavailable"
    end
    day = Interactions.DayIndex(at)
    greetingState = "first"
    tier = ContextProviders and ContextProviders.ResolveRelationshipTier
        and ContextProviders.ResolveRelationshipTier(relationship)
        or "reserved"
    eventID = "conversation:proximity_greeting:" .. actorKey .. ":"
        .. npcID .. ":day:" .. tostring(day)
    semanticContext = {
        npcID = npcID,
        relationshipState = relationship and relationship.state,
        relationshipAttitude = relationship and relationship.attitude,
        socialStyle = relationship and relationship.state == "friend"
            and "friendly" or nil,
    }
    if not RealizationAuthority
        or type(RealizationAuthority.Resolve) ~= "function"
    then
        return false, "semantic_realization_unavailable"
    end
    realization = RealizationAuthority.Resolve({
        poolID = "semantic.flow.greeting.opening",
        responsePlanID = "semantic.flow.greeting.opening",
        realizationFamily = "greeting",
        act = "GREET",
        topic = "greeting",
        context = semanticContext,
        salt = eventID,
    })
    if not realization then
        return false, "semantic_greeting_plan_unavailable"
    end
    -- This legacy ID is a content/transport alias only. The semantic plan and
    -- resolved text above are authoritative for conversational meaning.
    compatibilityFlavorID = "social_greeting_npc_" .. tostring(npcType)
        .. "_" .. tostring(tier) .. "_" .. tostring(greetingState)
    flavorID = compatibilityFlavorID
    before = relationshipSummary(relationship, true, npcID)
    applied, reason, details = Relationships.ApplyConversationEffect(
        npcID,
        actorKey,
        effectFor(definition),
        {
            blockID = "social_greeting",
            choiceID = "proximity_greeting",
            outcomeID = actorKey .. ":" .. npcID .. ":" .. tostring(day),
            eventID = eventID,
            interactionType = definition.id,
            worldAgeHours = at,
            sourceSystem = "proximity_greeting",
            interaction = {
                kind = "npc_proximity_greeting",
                source = "proximity_greeting",
                interactionType = definition.id,
                npcFlavorID = flavorID,
                semanticAct = realization.semanticAct,
                semanticTopic = realization.topic,
                responsePlanID = realization.responsePlanID,
                realizationFamily = realization.realizationFamily,
                realizationID = realization.realizationID,
                npcType = npcType,
                relationshipTier = tier,
                greetingState = greetingState,
                greetingDay = day,
                applied = true,
            },
        }
    )
    if applied ~= true then return false, reason or "not_applied" end
    afterRelationship = details and details.relationship or nil
    if not afterRelationship and Relationships.Get then
        afterRelationship = Relationships.Get(npcID, actorKey)
    end
    after = relationshipSummary(afterRelationship, true, npcID)
    delta = relationshipDelta(before, after)
    presentationEventID = details and details.eventID or eventID
    beatID = "beat:social_greeting:" .. tostring(presentationEventID)
    local interaction
    if InteractionLifecycle
        and type(InteractionLifecycle.Envelope) == "table"
        and type(InteractionLifecycle.Envelope.NPCSpeech) == "function"
        and InteractionPersistence
        and type(InteractionPersistence.RecordNPCSpeech) == "function"
    then
        interaction = InteractionLifecycle.Envelope.NPCSpeech({
            npcID = npcID,
            targetID = actorKey,
            playerUUID = actorKey,
            act = "GREET",
            topic = "greeting",
            beatID = beatID,
            responsePlanID = "social.greeting",
            eventRef = presentationEventID,
            flowID = "social_greeting",
            poolID = realization.realizationFamily,
            factRefs = greetingFactRefs(details),
            provenance = {
                responsePlanID = realization.responsePlanID,
                realizationFamily = realization.realizationFamily,
                realizationID = realization.realizationID,
            },
            worldHour = at,
        })
        if interaction then
            local recorded, recordReason =
                InteractionPersistence.RecordNPCSpeech({
                    npcID = npcID,
                    targetID = actorKey,
                    playerUUID = actorKey,
                    act = "GREET",
                    topic = "greeting",
                    beatID = beatID,
                    responsePlanID = "social.greeting",
                    eventRef = presentationEventID,
                    flowID = "social_greeting",
                    poolID = realization.realizationFamily,
                    factRefs = greetingFactRefs(details),
                    provenance = {
                        responsePlanID = realization.responsePlanID,
                        realizationFamily = realization.realizationFamily,
                        realizationID = realization.realizationID,
                    },
                    expectedReplies = { "GREET", "ACK", "THANK" },
                    worldHour = at,
                    meaningful = true,
                })
            if not recorded and PNC.Core
                and type(PNC.Core.LogWarn) == "function"
            then
                PNC.Core.LogWarn(
                    "social greeting lifecycle failed reason="
                        .. tostring(recordReason or "unknown")
                )
            end
        end
    end
    if PresentationAnimations and PresentationAnimations.Request then
        -- This greeting is authoritative but has no conversation lease, so
        -- keep it on the server-owned presentation path.
        PresentationAnimations.Request(
            record,
            target.body,
            "greeting.wavehi",
            {
                eventID = presentationEventID,
                reason = "proximity_greeting",
            }
        )
    end
    if Network and Network.SendConversationRelationshipForNPC then
        Network.SendConversationRelationshipForNPC(
            player,
            npcID,
            "proximity_greeting",
            {
                source = "proximity_greeting",
                eventID = presentationEventID,
                relationshipBefore = before,
                relationshipAfter = after,
                relationshipDelta = delta,
                npcID = npcID,
            }
        )
    end
    if Network and Network.SendSocialGreeting then
        Network.SendSocialGreeting(player, {
            eventID = presentationEventID,
            npcID = npcID,
            flavorID = flavorID,
            resolvedText = realization.fallback,
            semanticAct = realization.semanticAct,
            topic = realization.topic,
            responsePlanID = realization.responsePlanID,
            realizationFamily = realization.realizationFamily,
            realizationID = realization.realizationID,
            factRefs = realization.groundedFactRefs,
            npcType = npcType,
            relationshipTier = tier,
            greetingState = greetingState,
            greetingDay = day,
            relationshipBefore = before,
            relationshipAfter = after,
            relationshipDelta = delta,
            applied = true,
            memoryID = details and details.memoryID or nil,
            memoryType = details and details.memoryType
                or definition.targetMemory.type,
            interactionType = definition.id,
            interaction = interaction,
        })
    end
    return true, {
        npcID = npcID,
        eventID = details and details.eventID or eventID,
        flavorID = flavorID,
        resolvedText = realization.fallback,
        semanticAct = realization.semanticAct,
        topic = realization.topic,
        responsePlanID = realization.responsePlanID,
        realizationFamily = realization.realizationFamily,
        realizationID = realization.realizationID,
        factRefs = realization.groundedFactRefs,
        npcType = npcType,
        relationshipTier = tier,
        greetingState = greetingState,
        greetingDay = day,
        relationshipBefore = before,
        relationshipAfter = after,
        relationshipDelta = delta,
        applied = true,
        memoryID = details and details.memoryID or nil,
        memoryType = details and details.memoryType
            or definition.targetMemory.type,
        interactionType = definition.id,
    }
end


return Service
