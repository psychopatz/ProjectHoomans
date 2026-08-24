-- Conversation lease and registry-fingerprint validation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Internal = PNC.Conversation.Authority.Internal
local Registry = PNC.Conversation.Registry

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

local function requestIsCurrent(args)
    return tostring(args.registryFingerprint or "") == Registry.GetFingerprint()
end

Internal.ValidateLease = validateLease
Internal.RequestIsCurrent = requestIsCurrent

return Internal
