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
    npcType = Interactions and Interactions.ResolveNPCType
        and Interactions.ResolveNPCType(record) or "neutral"
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
    tier = Interactions.ResolveRelationshipTier(relationship)
    flavorID = Interactions.GreetingReplyFlavorID(
        npcType,
        tier,
        greetingState
    )
    eventID = "conversation:proximity_greeting:" .. actorKey .. ":"
        .. npcID .. ":day:" .. tostring(day)
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
        })
    end
    return true, {
        npcID = npcID,
        eventID = details and details.eventID or eventID,
        flavorID = flavorID,
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
