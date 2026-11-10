-- Canonical semantic context source projections.

local Sources = {}
Sources.NEED_KEYS = { "hunger", "thirst", "fatigue" }
Sources.CONDITION_KEYS = { "stress", "boredom", "panic" }

function Sources.numbersFor(source, keys, number)
    local values = {}
    if type(source) ~= "table" then return values end
    for index = 1, #keys do
        local key = keys[index]
        local value = number(source[key], nil)
        if value ~= nil then values[key] = value end
    end
    return values
end

function Sources.productionAudience(context, npc, player, relationship, copy)
    local Runtime = context.Runtime
    local hostility = type(npc.hostility) == "table" and npc.hostility or {}
    local entry = {
        id = npc.npcID or npc.id or "semantic-lab-npc",
        relationship = copy(relationship),
        tacticalClass = npc.tacticalClass,
        snapshot = {
            activeBehavior = npc.activeBehavior,
            followState = copy(npc.followState),
            hostility = copy(hostility),
            role = npc.role,
            recruited = npc.recruited,
            companion = npc.companion,
            ownedByPlayer = npc.ownedByPlayer,
            orderSpec = copy(npc.orderSpec),
            tacticalClass = npc.tacticalClass,
        },
        record = Runtime.hydratedNpcRecord,
    }
    local talkStart = PNC.Conversation
        and PNC.Conversation.TalkStart or nil
    if talkStart and type(talkStart.Project) == "function" then
        local ok, projection = pcall(
            talkStart.Project,
            entry,
            player,
            { source = "semantic_lab_context" }
        )
        if ok and type(projection) == "table" then
            return {
                audience = projection.audience,
                reason = projection.audienceReason,
                source = "PNC.Conversation.TalkStart.Project",
                relationshipID = projection.relationshipID,
                tacticalClass = projection.tacticalClass,
                playerHostile = projection.hostile == true,
                route = projection.route,
                routeReason = projection.routeReason,
            }
        end
    end
    return {
        audience = nil,
        reason = "production_talk_start_unavailable",
        source = "PNC.Conversation.TalkStart.Project",
        relationshipID = nil,
        tacticalClass = npc.tacticalClass,
        playerHostile = hostility.attackPlayers == true,
    }
end

function Sources.canonicalTacticalHostility(context, npc, audience, copy)
    local Runtime = context.Runtime
    local hostility = type(npc.hostility) == "table" and npc.hostility or {}
    local sourceKind = tostring(
        Runtime.sourceMetadata and Runtime.sourceMetadata.sourceKind
            or "FIXTURE"
    ):upper()
    local production = Runtime.hydratedNpcRecord ~= nil
    local source = sourceKind == "SAVE" and "SAVE" or "FIXTURE"
    local owner = production
        and "PNC.Persistence.DeserializeRecord"
        or "Developer/Test fixture"
    local reason
    if hostility.attackPlayers == true then
        reason = production
            and "persisted hostility.attackPlayers"
            or "explicit fixture hostility.attackPlayers"
    elseif hostility.mode ~= nil then
        reason = production
            and "persisted hostility.mode"
            or "explicit fixture hostility.mode"
    else
        reason = "no persisted tactical hostility"
    end
    return {
        mode = hostility.mode,
        attackPlayers = hostility.attackPlayers == true,
        tacticalClass = audience and audience.tacticalClass or npc.tacticalClass,
        activeBehavior = npc.activeBehavior,
        source = source,
        owner = owner,
        reason = reason,
        missingClass = sourceKind == "SAVE"
            and hostility.mode == nil
            and hostility.attackPlayers == nil
            and "LEGITIMATE_ABSENCE"
            or nil,
    }
end

function Sources.canonicalPersonalRelationship(context, relationship, copy)
    relationship = type(relationship) == "table" and relationship or {}
    local state = relationship.state or relationship.relationshipState or "unknown"
    local sourceKind = tostring(
        context.Runtime.sourceMetadata
            and context.Runtime.sourceMetadata.sourceKind or "FIXTURE"
    ):upper()
    local hasRecord = relationship.record ~= nil
        or relationship.productionGraph ~= nil
        or relationship.approval ~= nil
        or relationship.respect ~= nil
        or relationship.familiarity ~= nil
    return {
        state = state,
        source = sourceKind ~= "SAVE" and "FIXTURE"
            or hasRecord and "PNC.Relationships.Get" or "MISSING",
        reason = sourceKind ~= "SAVE"
            and "explicit Developer/Test relationship fixture"
            or hasRecord and "persisted NPC-to-Player relationship"
            or "no persisted NPC-to-Player relationship",
        missingClass = sourceKind == "SAVE" and not hasRecord
            and "LEGITIMATE_ABSENCE" or nil,
        approval = relationship.approval,
        respect = relationship.respect,
        familiarity = relationship.familiarity,
        baselineApproval = relationship.baselineApproval,
        baselineRespect = relationship.baselineRespect,
        previousState = relationship.previousState,
        identityTrust = relationship.identityTrust,
        revision = relationship.revision,
        interactionRevision = relationship.interactionRevision,
        bond = copy(relationship.bond),
    }
end

return Sources

