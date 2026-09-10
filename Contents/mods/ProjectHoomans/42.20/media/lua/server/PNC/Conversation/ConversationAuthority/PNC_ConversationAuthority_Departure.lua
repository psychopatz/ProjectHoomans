-- Server-authoritative warning/confirmation branch for colonist expulsion.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}

local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local ConversationRegistry = PNC.Conversation.Registry
local NPCRegistry = PNC.Registry
local validateLease = Internal.ValidateLease
local requestIsCurrent = Internal.RequestIsCurrent
local send = Internal.Send
local worldAgeHours = Internal.WorldAgeHours

local function reject(player, requestID, npcID, reason, details)
    local payload = {
        requestID = requestID,
        success = false,
        reason = reason or "departure_rejected",
        npcID = tostring(npcID or ""),
        responseKey = "response.departure.rejected",
    }
    for key, value in pairs(type(details) == "table" and details or {}) do
        payload[key] = value
    end
    send(player, PNC.Const.CMD_CONVERSATION_DEPARTURE_RESULT, payload)
    return false, payload.reason
end

function Authority.HandleDeparture(player, args)
    args = type(args) == "table" and args or {}
    local requestID = tostring(args.requestID or "")
    local npcID = tostring(args.npcID or "")
    local record = NPCRegistry.Get(npcID)
    local ok, reason, lease = validateLease(player, record, args.token)
    if requestID == "" then return false, "request_id_required" end
    if not ok or not lease then
        return reject(player, requestID, npcID, reason or "invalid_lease")
    end
    lease.processedConversationRequests =
        lease.processedConversationRequests or {}
    if lease.processedConversationRequests[requestID] then
        return reject(player, requestID, npcID, "replayed_request")
    end
    if not requestIsCurrent(args) then
        return reject(player, requestID, npcID, "registry_mismatch")
    end
    local context
    context, reason = Authority.BuildContext(player, record, args.token)
    if not context then return reject(player, requestID, npcID, reason) end
    local service = PNC.ColonistDeparture
    if not service or not service.CanPlayerManage then
        return reject(player, requestID, npcID,
            "departure_service_unavailable")
    end
    local managed, manageReason, ownerKey = service.CanPlayerManage(
        player, record, context.playerEntityKey
    )
    if not managed then
        return reject(player, requestID, npcID, manageReason)
    end
    lease.processedConversationRequests[requestID] = true
    if args.confirm ~= true then
        local preview = service.GetPreview
            and service.GetPreview(record, context.relationship) or nil
        send(player, PNC.Const.CMD_CONVERSATION_DEPARTURE_RESULT, {
            requestID = requestID,
            success = false,
            warning = true,
            reason = "departure_confirmation_required",
            npcID = npcID,
            responseKey = "response.departure.warning",
            departure = preview,
        })
        return false, "departure_confirmation_required"
    end

    local result
    ok, reason, result = service.Depart(record, "manual", {
        player = player,
        ownerKey = ownerKey,
        worldAgeHours = context.worldAgeHours or worldAgeHours(),
    })
    if not ok then
        return reject(player, requestID, npcID, reason or "departure_failed")
    end
    local penalty = result and result.penalty or nil
    send(player, PNC.Const.CMD_CONVERSATION_DEPARTURE_RESULT, {
        requestID = requestID,
        success = true,
        reason = reason or "colonist_departed",
        npcID = npcID,
        responseKey = "response.departure.confirmed",
        sourceFactionID = result and result.sourceFactionID,
        factionID = result and result.factionID,
        relationshipBefore = penalty and penalty.before or nil,
        relationshipAfter = penalty and penalty.after or nil,
        relationshipDelta = penalty and penalty.delta or nil,
        registryFingerprint = ConversationRegistry.GetFingerprint(),
        close = true,
        closeReason = "colonist_departed",
    })
    lease.conversationState = nil
    if PNC.ConversationScene and PNC.ConversationScene.End then
        PNC.ConversationScene.End(
            record,
            PNC.Registry.GetLiveZombie and PNC.Registry.GetLiveZombie(record.id)
                or nil,
            args.token,
            "colonist_departed"
        )
    end
    return true, "colonist_departed"
end

return Authority
