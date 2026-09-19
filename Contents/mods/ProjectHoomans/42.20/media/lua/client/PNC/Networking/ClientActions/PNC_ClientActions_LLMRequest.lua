-- LLM request lease transport for conversation integrations.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core
local Registry = PNC.Registry
local Internal = Client.Internal

function Client.ReserveLLMRequest(npcID, token, requestID)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local authority
    local internal
    local record
    local accepted
    local reason
    local args = {
        npcID = tostring(npcID or ""),
        token = tostring(token or ""),
        requestID = tostring(requestID or ""),
    }
    if not player or args.npcID == "" or args.token == ""
        or args.requestID == ""
    then
        return false, "llm_request_identity_missing"
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            return false, "network_api_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_LLM_REQUEST_RESERVE,
            args
        )
        Internal.TraceCompanionCommand("llm_request_reserve", npcID, "conversation", {
            requestID = requestID,
            origin = "llm_request",
        }, { status = "network_queued" })
        return true, "network_queued"
    end
    authority = PNC.Conversation and PNC.Conversation.Authority
    internal = authority and authority.Internal or nil
    record = Registry and Registry.Get and Registry.Get(args.npcID) or nil
    if not internal or not internal.ReserveLLMRequest or not record then
        return false, "llm_request_authority_unavailable"
    end
    accepted, reason = internal.ReserveLLMRequest(
        player,
        record,
        args.token,
        args.requestID
    )
    Internal.TraceCompanionCommand("llm_request_reserve", npcID, "conversation", {
        requestID = requestID,
        origin = "llm_request",
    }, { accepted = accepted == true, reason = reason })
    return accepted == true, reason or (
        accepted and "reserved" or "rejected"
    )
end

function Client.ReleaseLLMRequest(npcID, token, requestID, reason)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local authority
    local internal
    local record
    local accepted
    local releaseReason
    local args = {
        npcID = tostring(npcID or ""),
        token = tostring(token or ""),
        requestID = tostring(requestID or ""),
    }
    if not player or args.npcID == "" or args.token == ""
        or args.requestID == ""
    then
        return false, "llm_request_identity_missing"
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then
            return false, "network_api_unavailable"
        end
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_LLM_REQUEST_RELEASE,
            args
        )
        Internal.TraceCompanionCommand("llm_request_release", npcID, "conversation", {
            requestID = requestID,
            origin = "llm_request",
        }, { status = "network_queued" })
        return true, "network_queued"
    end
    authority = PNC.Conversation and PNC.Conversation.Authority
    internal = authority and authority.Internal or nil
    record = Registry and Registry.Get and Registry.Get(args.npcID) or nil
    if not internal or not internal.ReleaseLLMRequest or not record then
        return false, "llm_request_authority_unavailable"
    end
    accepted, releaseReason = internal.ReleaseLLMRequest(
        player,
        record,
        args.token,
        args.requestID,
        tostring(reason or "request_completed")
    )
    Internal.TraceCompanionCommand("llm_request_release", npcID, "conversation", {
        requestID = requestID,
        origin = "llm_request",
    }, { accepted = accepted == true, reason = releaseReason })
    return accepted == true, releaseReason or (
        accepted and "released" or "rejected"
    )
end

return Client

