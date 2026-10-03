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

Internal.EventMutation = {
    Relationships = Relationships,
    Types = Types,
    Math = Math,
    Constants = Constants,
    isAuthority = isAuthority,
    resolveObserver = resolveObserver,
    validateTarget = validateTarget,
    getRelationship = getRelationship,
    buildMemorySpec = buildMemorySpec,
    findMemory = findMemory,
    hasRecentEvent = hasRecentEvent,
    appendRecentEvent = appendRecentEvent,
    finiteNumber = finiteNumber,
    commit = commit,
}

require "PNC/Social/RelationshipService/PNC_RelationshipService_EventMutation_Apply"

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
