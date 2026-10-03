-- Server-side conversation choice response and delivery boundary.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local ChoiceResponse = {}

local send = Internal.Send

function ChoiceResponse.Reject(state, reason)
    local args = state.args
    send(state.player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
        requestID = args.requestID,
        success = false,
        reason = reason,
        npcID = tostring(args.npcID or ""),
    })
    return false, reason
end

function ChoiceResponse.Send(state)
    send(
        state.player,
        PNC.Const.CMD_CONVERSATION_OUTCOME,
        state.payload
    )
    if state.payload.close then
        state.lease.conversationState = nil
    end
    return true, state.outcome.id
end

Internal.ChoiceHandleResponse = ChoiceResponse

return ChoiceResponse
