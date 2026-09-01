if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}
PNC.Relationships.Internal = PNC.Relationships.Internal or {}

local Relationships = PNC.Relationships
local Internal = Relationships.Internal
local Types = PNC.RelationshipTypes
local Math = PNC.RelationshipMath
local Constants = PNC.RelationshipConstants
local isAuthority = Internal.isAuthority
local resolveObserver = Internal.resolveObserver
local validateTarget = Internal.validateTarget
local getRelationship = Internal.getRelationship
local buildMemorySpec = Internal.buildMemorySpec
local findMemory = Internal.findMemory
local hasRecentEvent = Internal.hasRecentEvent
local appendRecentEvent = Internal.appendRecentEvent
local finiteNumber = Internal.finiteNumber
local commit = Internal.commit

-- Atomic Phase 2 mutation boundary. Social-event processing owns definition
-- lookup and attribution; this API owns all persistent relationship changes.
function Relationships.ApplyEventMutation(
    observerNPCID,
    targetKey,
    mutation
)
    local record
    local reason
    local social
    local relationship
    local memory
    local eventID
    local interactionType
    local worldAgeHours
    local familiarityDelta
    local moraleDelta
    local saturationType
    local saturation
    local cooldownType
    local cooldownUntil
    local withinLimit
    if not isAuthority() then
        return false, "not_authority"
    end
    if type(mutation) ~= "table" then
        return false, "invalid_event_mutation"
    end
    eventID = type(mutation.eventID) == "string"
        and mutation.eventID or nil
    interactionType = type(mutation.interactionType) == "string"
        and mutation.interactionType or nil
    worldAgeHours = finiteNumber(mutation.worldAgeHours)
    familiarityDelta = finiteNumber(mutation.familiarityDelta) or 0
    moraleDelta = finiteNumber(mutation.moraleDelta) or 0
    if not eventID or eventID == "" or not worldAgeHours
        or worldAgeHours < 0
    then
        return false, "invalid_event_mutation"
    end
    record, reason = resolveObserver(observerNPCID)
    if not record then
        return false, reason
    end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then
        return false, reason
    end
    memory = Types.NewMemory(buildMemorySpec(mutation.memory, targetKey))
    if not memory or memory.aboutKey ~= targetKey then
        return false, "invalid_memory"
    end
    social = Types.NormalizeSocialState(
        record.social,
        record.identitySeed,
        record.archetypeID
    )
    if hasRecentEvent(social, eventID) then
        return false, "duplicate_event"
    end
    relationship = getRelationship(record, targetKey)
    relationship = relationship
        and Types.NormalizeRelationship(relationship, targetKey)
        or Types.NewRelationship(targetKey)
    if findMemory(relationship, memory.id) then
        return false, "duplicate_memory_id"
    end
    cooldownType = type(mutation.cooldownType) == "string"
        and mutation.cooldownType or nil
    cooldownUntil = finiteNumber(mutation.cooldownUntil)
    if cooldownType and cooldownUntil then
        relationship.cooldowns[cooldownType] =
            math.max(0, cooldownUntil)
    end
    saturationType = type(mutation.saturationType) == "string"
        and mutation.saturationType or nil
    saturation = type(mutation.saturation) == "table"
        and mutation.saturation or nil
    if saturationType and saturation then
        relationship.saturation[saturationType] = {
            approval = finiteNumber(saturation.approval) or 0,
            respect = finiteNumber(saturation.respect) or 0,
        }
    end
    relationship.memories[#relationship.memories + 1] = memory
    relationship.familiarity = math.max(
        Constants.FAMILIARITY_MIN,
        math.min(
            Constants.FAMILIARITY_MAX,
            (tonumber(relationship.familiarity) or 0)
                + familiarityDelta
        )
    )
    relationship.lastInteractionAt = math.max(
        tonumber(relationship.lastInteractionAt) or 0,
        worldAgeHours
    )
    relationship, _, withinLimit = Math.PruneMemories(
        relationship,
        targetKey,
        worldAgeHours,
        Constants.MEMORY_LIMIT
    )
    if not withinLimit then
        return false, "permanent_memory_limit"
    end
    if not findMemory(relationship, memory.id) then
        return false, "memory_pruned_by_limit"
    end
    relationship = Math.RecalculateRelationship(
        relationship,
        targetKey,
        worldAgeHours
    )
    social.morale = math.max(
        Constants.MORALE_MIN,
        math.min(
            Constants.MORALE_MAX,
            (tonumber(social.morale) or 0) + moraleDelta
        )
    )
    appendRecentEvent(social, eventID)
    commit(
        record,
        social,
        targetKey,
        relationship,
        true,
        worldAgeHours,
        {
            kind = "social_event",
            eventID = eventID,
            memoryID = memory.id,
            memoryType = memory.type,
            interactionType = interactionType,
            knowledgeSource = memory.knowledgeSource,
            interaction = mutation.interaction or {
                kind = mutation.sourceSystem or "social_event",
                source = mutation.sourceSystem,
                interactionType = interactionType,
                eventID = eventID,
                memoryID = memory.id,
                memoryType = memory.type,
                at = worldAgeHours,
                worldAgeHours = worldAgeHours,
                applied = true,
            },
        }
    )
    return true, "applied", {
        relationship = Types.NormalizeRelationship(
            record.social.relationships[targetKey],
            targetKey
        ),
        morale = record.social.morale,
        memoryID = memory.id,
        eventID = eventID,
        memoryType = memory.type,
        interactionType = interactionType,
    }
end

-- Conversation outcomes use the normal directed relationship/memory mutation
-- boundary. They do not maintain a second, block-local points system.
function Relationships.ApplyConversationEffect(
    observerNPCID,
    targetKey,
    effect,
    context
)
    effect = type(effect) == "table" and effect or {}
    context = type(context) == "table" and context or {}
    local at = math.max(0, tonumber(context.worldAgeHours) or 0)
    local suppliedEventID = type(context.eventID) == "string"
        and context.eventID or nil
    local identity = table.concat({
        tostring(context.blockID or "block"),
        tostring(context.choiceID or "choice"),
        tostring(context.outcomeID or "outcome"),
        tostring(math.floor(at * 1000)),
    }, ":")
    local memoryID = suppliedEventID and suppliedEventID
        or "conversation:" .. identity
    local memoryType = type(effect.memoryType) == "string"
        and effect.memoryType or "conversation_outcome"
    local interactionType = type(effect.interactionType) == "string"
        and effect.interactionType or memoryType
    local tags = type(effect.tags) == "table"
        and effect.tags or { conversation = true }
    tags.conversation = true
    return Relationships.ApplyEventMutation(observerNPCID, targetKey, {
        eventID = memoryID,
        worldAgeHours = at,
        interactionType = interactionType,
        familiarityDelta = tonumber(effect.familiarity) or 0,
        moraleDelta = tonumber(effect.morale) or 0,
        memory = {
            id = memoryID,
            type = memoryType,
            aboutKey = targetKey,
            createdAt = at,
            lastEvaluatedAt = at,
            approvalEffect = tonumber(effect.approval) or 0,
            respectEffect = tonumber(effect.respect) or 0,
            moraleEffect = 0,
            strength = 1,
            decayPerDay = tonumber(effect.decayPerDay) or 0.05,
            permanent = effect.permanent == true,
            shareable = effect.shareable == true,
            knowledgeSource = "experienced",
            sourceKey = targetKey,
            tags = tags,
        },
        cooldownType = context.cooldownType,
        cooldownUntil = context.cooldownUntil,
        sourceSystem = context.sourceSystem,
        interaction = context.interaction or {
            kind = context.interactionKind or "conversation",
            source = context.sourceSystem or "conversation",
            interactionType = interactionType,
            eventID = memoryID,
            blockID = context.blockID,
            categoryID = context.categoryID,
            nodeID = context.nodeID,
            choiceID = context.choiceID,
            outcomeID = context.outcomeID,
            at = at,
            worldAgeHours = at,
            applied = true,
        },
    })
end
