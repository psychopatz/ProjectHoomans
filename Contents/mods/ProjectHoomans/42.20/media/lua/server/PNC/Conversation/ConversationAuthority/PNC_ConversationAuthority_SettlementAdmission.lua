-- Server-authoritative one-NPC settlement admission requests.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}

local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local Registry = PNC.Conversation.Registry
local validateLease = Internal.ValidateLease
local requestIsCurrent = Internal.RequestIsCurrent
local send = Internal.Send
local worldAgeHours = Internal.WorldAgeHours

local function reject(player, requestID, npcID, reason, details)
    local payload = {
        requestID = requestID,
        success = false,
        reason = reason,
        npcID = tostring(npcID or ""),
    }
    for key, value in pairs(type(details) == "table" and details or {}) do
        payload[key] = value
    end
    send(player, PNC.Const.CMD_CONVERSATION_SETTLEMENT_ADMISSION_RESULT,
        payload)
    return false, reason
end

function Authority.HandleSettlementAdmission(player, args)
    args = type(args) == "table" and args or {}
    local requestID = tostring(args.requestID or "")
    local npcID = tostring(args.npcID or "")
    local record = PNC.Registry.Get(npcID)
    local ok
    local reason
    local lease
    local context
    local result
    if requestID == "" then return false, "request_id_required" end
    ok, reason, lease = validateLease(player, record, args.token)
    if not ok or not lease then
        return reject(player, requestID, npcID, reason or "invalid_lease")
    end
    lease.processedConversationRequests =
        lease.processedConversationRequests or {}
    if lease.processedConversationRequests[requestID] then
        return reject(player, requestID, npcID, "replayed_request")
    end
    if not requestIsCurrent(args) then
        return reject(player, requestID, npcID, "registry_mismatch", {
            registryFingerprint = Registry.GetFingerprint(),
        })
    end
    context, reason = Authority.BuildContext(player, record, args.token)
    if not context then return reject(player, requestID, npcID, reason) end
    if context.audiences.hostile then
        return reject(player, requestID, npcID, "hostile_audience")
    end
    if not PNC.MobileSettlementVisitService
        or not PNC.MobileSettlementVisitService.AdmitPlayer
    then
        return reject(player, requestID, npcID, "admission_service_unavailable")
    end
    ok, reason, result = PNC.MobileSettlementVisitService.AdmitPlayer(
        player,
        npcID,
        args.visitID,
        worldAgeHours()
    )
    lease.processedConversationRequests[requestID] = true
    if not ok then return reject(player, requestID, npcID, reason) end
    send(player, PNC.Const.CMD_CONVERSATION_SETTLEMENT_ADMISSION_RESULT, {
        requestID = requestID,
        success = true,
        reason = reason or "settlement_member_admitted",
        npcID = npcID,
        responseKey = "response.settlement_admission.accepted.1",
        npcReaction = "relieved",
        admission = result,
        registryFingerprint = Registry.GetFingerprint(),
        close = true,
        closeReason = "settlement_member_admitted",
    })
    lease.conversationState = nil
    return true, "settlement_member_admitted"
end

return Authority
