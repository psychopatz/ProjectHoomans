-- Server-side recruitment response and delivery boundary.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local Registry = PNC.Conversation.Registry
local RecruitmentResponse = {}

local recruitReplyKey = Internal.RecruitReplyKey
local send = Internal.Send
local worldAgeHours = Internal.WorldAgeHours

function RecruitmentResponse.Reject(state, rejection, details)
    local args = state.args
    local payload = {
        requestID = state.requestID,
        success = false,
        reason = rejection,
        npcID = tostring(args.npcID or ""),
    }
    for key, value in pairs(type(details) == "table" and details or {}) do
        payload[key] = value
    end
    if payload.npcReaction == "declined" then
        payload.responseKey = recruitReplyKey(
            args.npcID,
            rejection,
            nil,
            worldAgeHours()
        )
    end
    send(state.player, PNC.Const.CMD_CONVERSATION_RECRUIT_RESULT, payload)
    return false, rejection
end

function RecruitmentResponse.Send(state)
    local args = state.args
    local context = state.context
    local result = state.result
    local payload = {
        requestID = state.requestID,
        success = true,
        reason = state.reason or "recruited",
        npcID = tostring(args.npcID or ""),
        route = result and result.route,
        responseKey = recruitReplyKey(
            args.npcID,
            nil,
            result and result.route,
            context.worldAgeHours
        ),
        relationship = result and result.relationship,
        registryFingerprint = Registry.GetFingerprint(),
        close = true,
        closeReason = "recruited",
    }
    send(
        state.player,
        PNC.Const.CMD_CONVERSATION_RECRUIT_RESULT,
        payload
    )
    state.lease.conversationState = nil
    return true, "recruited"
end

Internal.RecruitHandleResponse = RecruitmentResponse

return RecruitmentResponse
