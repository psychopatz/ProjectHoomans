if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

if not PNC or not PNC.Conversation
    or not PNC.Conversation.Authority
then return end

local Authority = PNC.Conversation.Authority
local H = Authority.Internal.LLMSocialReaction
if not H then return Authority end

local log = H.log
local rejected = H.rejected
if not H.ReplayCachedReaction then
    require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_LeaseLifecycle"
end
if not H.AdmitReaction then
    require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_Admission"
end
local admitReaction = H.AdmitReaction
if not H.ApplyRelationshipEffect then
    require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_ApplyEffect"
end
local applyRelationshipEffect = H.ApplyRelationshipEffect
if not H.BuildReactionResult then
    require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_BuildResult"
end
local buildReactionResult = H.BuildReactionResult
if not H.DeliverReactionResult then
    require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_DeliverResult"
end
local deliverReactionResult = H.DeliverReactionResult
local recordAppliedReaction = H.RecordAppliedReaction

function Authority.HandleLLMSocialReaction(player, args)
    args = type(args) == "table" and args or {}
    if type(admitReaction) ~= "function" then
        return rejected(player, args, "social_admission_unavailable")
    end
    local admission, earlyResult = admitReaction(player, args)
    if earlyResult then return earlyResult end
    if type(admission) ~= "table" then
        return rejected(player, args, "social_admission_unavailable")
    end
    local requestID = admission.requestID
    local callID = admission.callID
    local npcID = admission.npcID
    local reaction = admission.reaction
    local intensity = admission.intensity
    local subtype = admission.subtype
    local record = admission.record
    local lease = admission.lease
    local pendingRequest = admission.pendingRequest
    local targetKey = admission.targetKey
    local before = admission.before
    local beforeExists = admission.beforeExists
    local at = admission.occurredAt
    local idempotencyKey = admission.idempotencyKey
    local after
    local applied
    local reason
    local details
    local cooldownType
    local cooldownUntil
    local result
    if type(applyRelationshipEffect) ~= "function" then
        return rejected(player, args, "social_effect_processor_unavailable")
    end
    applied, reason, details, cooldownType, cooldownUntil =
        applyRelationshipEffect({
            reaction = reaction,
            intensity = intensity,
            subtype = subtype,
            npcID = npcID,
            targetKey = targetKey,
            requestID = requestID,
            callID = callID,
            occurredAt = at,
        })
    if applied ~= true then
        log(
            "social_react_apply_failed",
            "npc=" .. npcID .. " request=" .. requestID
                .. " call=" .. callID .. " reaction=" .. reaction
                .. " reason=" .. tostring(reason or "relationship_rejected")
        )
        return rejected(player, args, reason or "relationship_rejected")
    end

    if type(buildReactionResult) ~= "function" then
        return rejected(player, args, "social_result_builder_unavailable")
    end
    result, after = buildReactionResult({
        player = player,
        record = record,
        npcID = npcID,
        targetKey = targetKey,
        requestID = requestID,
        callID = callID,
        reaction = reaction,
        intensity = intensity,
        subtype = subtype,
        before = before,
        beforeExists = beforeExists,
        reason = reason,
        details = details,
        occurredAt = at,
        cooldownType = cooldownType,
        cooldownUntil = cooldownUntil,
    })
    if type(recordAppliedReaction) ~= "function" then
        return rejected(player, args, "social_lease_lifecycle_unavailable")
    end
    recordAppliedReaction(lease, idempotencyKey, result, pendingRequest)
    log(
        "social_react_applied",
        "npc=" .. npcID .. " request=" .. requestID
            .. " call=" .. callID .. " reaction=" .. reaction
            .. " memory=" .. tostring(result.memoryID or "")
            .. " event=" .. tostring(details and details.eventID or "")
    .. " after_approval=" .. tostring(after.approval or 0)
        .. " after_respect=" .. tostring(after.respect or 0)
            .. " revision=" .. tostring(result.relationshipRevision or "")
    )
    if type(deliverReactionResult) ~= "function" then
        return rejected(player, args, "social_result_delivery_unavailable")
    end
    deliverReactionResult(player, result)
    return result
end

return Authority
