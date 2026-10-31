if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Builds the authoritative result projection for an applied LLM reaction.

if not PNC or not PNC.Conversation
    or not PNC.Conversation.Authority
then return end

local Authority = PNC.Conversation.Authority
local H = Authority.Internal and Authority.Internal.LLMSocialReaction
if not H then return Authority end

local Policy = H.Policy
local buildReplyContext = H.buildReplyContext
local relationshipFor = H.relationshipFor
local summaryOf = H.summaryOf
local summaryFor = H.summaryFor

function H.BuildReactionResult(context)
    context = type(context) == "table" and context or {}
    local player = context.player
    local record = context.record
    local npcID = context.npcID
    local targetKey = context.targetKey
    local requestID = context.requestID
    local callID = context.callID
    local reaction = context.reaction
    local intensity = context.intensity
    local subtype = context.subtype
    local before = context.before
    local beforeExists = context.beforeExists == true
    local reason = context.reason
    local details = context.details
    local at = context.occurredAt
    local after = relationshipFor(npcID, targetKey) or {}
    local relationshipSummary = summaryFor(player, npcID, after)
    local relationshipBefore = summaryOf(before, beforeExists, npcID)
    local relationshipAfter = relationshipSummary
        or summaryOf(after, true, npcID)
    local capabilities = Policy.BuildCapabilities
        and Policy.BuildCapabilities(record, player, after, at) or nil
    local relationshipDelta = {
        approval = (tonumber(after.approval) or 0)
            - (tonumber(before.approval) or 0),
        respect = (tonumber(after.respect) or 0)
            - (tonumber(before.respect) or 0),
        familiarity = (tonumber(after.familiarity) or 0)
            - (tonumber(before.familiarity) or 0),
    }
    local result = {
        requestID = requestID,
        callID = callID,
        npcID = npcID,
        tool = "social_react",
        accepted = true,
        reason = reason or "applied",
        reaction = reaction,
        intensity = intensity,
        subtype = subtype,
        explicit = subtype == "sexual_advance",
        replyContext = buildReplyContext(
            reaction,
            subtype,
            true,
            reason or "applied"
        ),
        relationship = relationshipSummary,
        relationshipBefore = relationshipBefore,
        relationshipAfter = relationshipAfter,
        relationshipDelta = relationshipDelta,
        relationshipRevision = relationshipSummary
            and relationshipSummary.revision or nil,
        memoryID = details and details.memoryID or nil,
        memoryType = details and details.memoryType or nil,
        interactionType = details and details.interactionType or nil,
        eventID = details and details.eventID or nil,
        capabilities = capabilities,
        policyVersion = Policy.VERSION,
        cooldownType = context.cooldownType,
        cooldownUntil = context.cooldownUntil,
        approvalDelta = relationshipDelta.approval,
        respectDelta = relationshipDelta.respect,
        familiarityDelta = relationshipDelta.familiarity,
    }
    return result, after
end

return Authority
