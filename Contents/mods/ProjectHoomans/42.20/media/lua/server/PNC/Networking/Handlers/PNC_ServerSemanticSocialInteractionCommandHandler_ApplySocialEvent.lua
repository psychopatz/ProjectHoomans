if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Applies an admitted semantic social interaction on the server.

if not PNC or not PNC.SemanticDialogueSocialAuthority
then return end

local Authority = PNC.SemanticDialogueSocialAuthority
local H = Authority.Internal and Authority.Internal.SemanticSocial
if not H then return Authority end

local SocialEvents = H.SocialEvents
local Core = PNC.Core
local rejected = H.rejected
local relationshipDelta = H.relationshipDelta
local relationshipSummary = H.relationshipSummary
local detailFor = H.detailFor
local sendRelationship = H.sendRelationship

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function effectSummary(value)
    value = type(value) == "table" and value or {}
    return {
        approval = tonumber(value.approvalEffect) or 0,
        respect = tonumber(value.respectEffect) or 0,
        familiarity = tonumber(value.familiarityGain) or 0,
    }
end

local function hasVisibleRelationshipChange(delta)
    return type(delta) == "table"
        and (
            (tonumber(delta.approval) or 0) ~= 0
            or (tonumber(delta.respect) or 0) ~= 0
            or (tonumber(delta.familiarity) or 0) ~= 0
        )
end

function H.ApplySocialEvent(context)
    context = type(context) == "table" and context or {}
    local player = context.player
    local npcID = context.npcID
    local requestID = context.requestID
    local speechAct = context.speechAct
    local conversationID = context.conversationID
    local actorKey = context.actorKey
    local targetKey = context.targetKey
    local eventType = context.eventType
    local at = context.occurredAt
    local eventID = table.concat({
        "social:semantic_dialogue",
        tostring(actorKey),
        tostring(npcID),
        tostring(conversationID),
        tostring(requestID),
    }, ":")
    local processed = SocialEvents.Emit({
        id = eventID,
        type = eventType,
        actorKey = actorKey,
        targetKey = targetKey,
        occurredAt = at,
        sourceSystem = "semantic_dialogue",
        context = {
            conversationID = conversationID,
            speechAct = speechAct,
        },
    })
    if type(processed) ~= "table" or processed.ok ~= true then
        return rejected(requestID, npcID, speechAct,
            processed and processed.reason or "social_event_rejected")
    end

    local detail = detailFor(processed, npcID, actorKey)
    if detail then
        sendRelationship(
            player,
            npcID,
            requestID,
            eventID,
            eventType,
            detail
        )
    end

    local beforeSummary = detail and relationshipSummary(
        detail.relationshipBefore,
        true,
        npcID
    ) or nil
    local afterSummary = detail and relationshipSummary(
        detail.relationshipAfter,
        true,
        npcID
    ) or nil
    local delta = relationshipDelta(beforeSummary, afterSummary)
    local memoryRecorded = (tonumber(processed.relationshipsChanged) or 0) > 0
    local visibleChange = hasVisibleRelationshipChange(delta)
    local accepted = (tonumber(processed.relationshipsChanged) or 0) > 0
    return {
        accepted = accepted,
        authority = "server",
        status = accepted and "applied" or "rejected",
        reason = accepted
            and (visibleChange and nil or "relationship_clamped")
            or "relationship_not_changed",
        requestID = requestID,
        npcID = npcID,
        speechAct = speechAct,
        eventID = eventID,
        eventType = eventType,
        relationshipBefore = beforeSummary,
        relationshipAfter = afterSummary,
        relationshipDelta = delta,
        memoryRecorded = memoryRecorded,
        visibleRelationshipChange = visibleChange,
        requestedEffects = effectSummary(detail and detail.modifiedEffects),
        baseEffects = effectSummary(detail and detail.baseEffects),
        saturationBefore = copy(detail and detail.saturationBefore),
        saturationAfter = copy(detail and detail.saturationAfter),
    }
end

return Authority
