if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Owns request admission for the authoritative LLM social reaction command.
-- This boundary normalizes input, authorizes the lease, and evaluates policy.

if not PNC or not PNC.Conversation
    or not PNC.Conversation.Authority
then return end

local Authority = PNC.Conversation.Authority
local H = Authority.Internal and Authority.Internal.LLMSocialReaction
if not H then return Authority end

local worldAgeHours = H.worldAgeHours
local rejected = H.rejected
if not H.NormalizeReactionRequest then
    require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_AdmissionRequest"
end
if not H.ReplayCachedReaction then
    require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_LeaseLifecycle"
end
if not H.AuthorizeReactionLease then
    require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_AdmissionLease"
end
if not H.EvaluateReactionAdmission then
    require "PNC/Networking/Handlers/PNC_ServerLLMSocialReactionCommandHandler_AdmissionPolicy"
end
local normalizeReactionRequest = H.NormalizeReactionRequest
local authorizeReactionLease = H.AuthorizeReactionLease
local evaluateReactionAdmission = H.EvaluateReactionAdmission

function H.AdmitReaction(player, args)
    if type(normalizeReactionRequest) ~= "function" then
        return nil, rejected(player, args, "social_admission_request_unavailable")
    end
    local request, earlyResult = normalizeReactionRequest(player, args)
    if earlyResult then return nil, earlyResult end
    if type(request) ~= "table" then
        return nil, rejected(player, args, "social_admission_request_unavailable")
    end
    args = request.args
    local requestID = request.requestID
    local callID = request.callID
    local npcID = request.npcID
    local token = request.token
    local reaction = request.reaction
    local intensity = request.intensity
    local subtype = request.subtype
    local record = request.record

    if type(authorizeReactionLease) ~= "function" then
        return nil, rejected(player, args, "social_lease_lifecycle_unavailable")
    end
    local lease
    local pendingRequest
    local idempotencyKey
    local leaseEarlyResult
    lease, pendingRequest, idempotencyKey, leaseEarlyResult =
        authorizeReactionLease({
            player = player,
            args = args,
            record = record,
            token = token,
            requestID = requestID,
            callID = callID,
            npcID = npcID,
        })
    if leaseEarlyResult then return nil, leaseEarlyResult end

    if not PNC.PlayerCharacters or not PNC.PlayerCharacters.GetEntityKey then
        return nil, rejected(player, args, "player_identity_unavailable")
    end
    local targetKey
    local reason
    targetKey, reason = PNC.PlayerCharacters.GetEntityKey(player, {
        callback = "llm_social_reaction",
        worldAgeHours = worldAgeHours(),
    })
    if not targetKey then
        return nil, rejected(player, args, reason)
    end

    if type(evaluateReactionAdmission) ~= "function" then
        return nil, rejected(
            player,
            args,
            "social_reaction_policy_unavailable"
        )
    end
    local before
    local beforeExists
    local at
    local earlyResult
    before, beforeExists, at, earlyResult = evaluateReactionAdmission({
        player = player,
        args = args,
        npcID = npcID,
        requestID = requestID,
        callID = callID,
        reaction = reaction,
        intensity = intensity,
        subtype = subtype,
        record = record,
        targetKey = targetKey,
    })
    if earlyResult then return nil, earlyResult end

    return {
        requestID = requestID,
        callID = callID,
        npcID = npcID,
        token = token,
        reaction = reaction,
        intensity = intensity,
        subtype = subtype,
        record = record,
        lease = lease,
        pendingRequest = pendingRequest,
        targetKey = targetKey,
        before = before,
        beforeExists = beforeExists,
        occurredAt = at,
        idempotencyKey = idempotencyKey,
    }, nil
end

return Authority
