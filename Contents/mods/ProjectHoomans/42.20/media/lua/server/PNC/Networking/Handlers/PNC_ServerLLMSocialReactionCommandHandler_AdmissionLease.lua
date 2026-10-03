if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Owns lease authorization, duplicate replay, and consumed-request checks.
-- This provider does not resolve player identity or evaluate reaction policy.

if not PNC or not PNC.Conversation
    or not PNC.Conversation.Authority
then return end

local Authority = PNC.Conversation.Authority
local H = Authority.Internal and Authority.Internal.LLMSocialReaction
if not H then return Authority end

local playerOwnsLease = H.playerOwnsLease
local rejected = H.rejected
local replayCachedReaction = H.ReplayCachedReaction

function H.AuthorizeReactionLease(context)
    context = type(context) == "table" and context or {}
    local player = context.player
    local args = context.args
    local record = context.record
    local token = context.token
    local requestID = context.requestID
    local callID = context.callID
    local npcID = context.npcID
    local internal = Authority.Internal or {}
    if not internal.ValidateLLMRequest and not internal.ValidateLease then
        return nil, nil, nil, rejected(
            player,
            args,
            "conversation_authority_unavailable"
        )
    end

    local leaseOK
    local reason
    local lease
    if internal.ValidateLLMRequest then
        leaseOK, reason, lease = internal.ValidateLLMRequest(
            player,
            record,
            token,
            requestID
        )
    else
        leaseOK, reason, lease = internal.ValidateLease(player, record, token)
    end
    if not leaseOK then
        return nil, nil, nil, rejected(player, args, reason)
    end
    if not playerOwnsLease(player, lease) then
        return nil, nil, nil, rejected(
            player,
            args,
            "conversation_player_mismatch"
        )
    end

    if type(replayCachedReaction) ~= "function" then
        return nil, nil, nil, rejected(
            player,
            args,
            "social_lease_lifecycle_unavailable"
        )
    end
    local result
    local idempotencyKey
    result, idempotencyKey = replayCachedReaction({
        lease = lease,
        player = player,
        npcID = npcID,
        requestID = requestID,
        callID = callID,
    })
    if result then
        return nil, nil, nil, result
    end

    local pendingRequest = lease.requestID ~= nil
    if pendingRequest and lease.consumed == true then
        return nil, nil, nil, rejected(player, args, "llm_request_consumed")
    end
    return lease, pendingRequest, idempotencyKey, nil
end

return Authority
