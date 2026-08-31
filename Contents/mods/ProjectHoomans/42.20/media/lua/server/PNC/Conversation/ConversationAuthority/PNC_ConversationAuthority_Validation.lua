-- Conversation lease and registry-fingerprint validation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Internal = PNC.Conversation.Authority.Internal
local Registry = PNC.Conversation.Registry
local Scene = PNC.ConversationScene

local function validateLease(player, record, token)
    local zombie = record and PNC.Registry.GetLiveZombie(record.id) or nil
    local lease = record and record.runtime and record.runtime.conversationLease
    if not lease or tostring(lease.token or "") ~= tostring(token or "") then
        return false, "invalid_lease"
    end
    local ok, reason = PNC.ConversationScene.Begin(record, zombie, player, token, {
        maximumDistance = lease.maximumDistance,
        dangerRadius = lease.dangerRadius,
        allowHostileParley = lease.hostileParley == true,
    })
    return ok == true, reason, lease
end

local function reserveLLMRequest(player, record, token, requestID)
    local zombie = record and PNC.Registry.GetLiveZombie(record.id) or nil
    if not Scene or not Scene.ReserveLLMRequest then
        return false, "conversation_authority_unavailable"
    end
    return Scene.ReserveLLMRequest(
        record,
        zombie,
        player,
        token,
        requestID
    )
end

local function releaseLLMRequest(player, record, token, requestID, reason)
    if not Scene or not Scene.ReleaseLLMRequest then
        return false, "conversation_authority_unavailable"
    end
    return Scene.ReleaseLLMRequest(
        record,
        player,
        token,
        requestID,
        reason
    )
end

local function validateLLMRequest(player, record, token, requestID)
    local runtime = record and record.runtime or nil
    local pending = runtime and runtime.llmRequestLease or nil
    local zombie
    if pending then
        zombie = record and PNC.Registry.GetLiveZombie(record.id) or nil
        if not Scene or not Scene.ValidateLLMRequest then
            return false, "conversation_authority_unavailable"
        end
        return Scene.ValidateLLMRequest(
            record,
            zombie,
            player,
            token,
            requestID
        )
    end
    return validateLease(player, record, token)
end

local function requestIsCurrent(args)
    return tostring(args.registryFingerprint or "") == Registry.GetFingerprint()
end

Internal.ValidateLease = validateLease
Internal.ReserveLLMRequest = reserveLLMRequest
Internal.ReleaseLLMRequest = releaseLLMRequest
Internal.ValidateLLMRequest = validateLLMRequest
Internal.RequestIsCurrent = requestIsCurrent

return Internal
