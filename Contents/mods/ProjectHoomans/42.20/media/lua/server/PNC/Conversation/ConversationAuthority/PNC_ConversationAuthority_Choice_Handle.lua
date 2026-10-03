-- Server-authoritative conversation choice coordinator.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local ChoiceContext = Internal.ChoiceHandleContext
local ChoiceEffects = Internal.ChoiceHandleEffects
local ChoiceResponse = Internal.ChoiceHandleResponse

if not ChoiceContext or not ChoiceEffects or not ChoiceResponse then
    return Authority
end

function Authority.HandleChoice(player, args)
    args = type(args) == "table" and args or {}
    if type(args.requestID) ~= "string" or args.requestID == "" then
        return false, "request_id_required"
    end
    local state = ChoiceContext.Build(player, args)
    if state.silent then return false, state.reason end
    if state.reason then
        return ChoiceResponse.Reject(state, state.reason)
    end
    local committed, reason = ChoiceEffects.Commit(state)
    if not committed then
        return ChoiceResponse.Reject(state, reason)
    end
    return ChoiceResponse.Send(state)
end

return Authority
