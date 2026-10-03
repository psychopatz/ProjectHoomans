local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal
local ReceiveContext = Internal.OutcomeReceiveContext
local ReceivePresentation = Internal.OutcomeReceivePresentation

if not ReceiveContext or not ReceivePresentation then return Composer end

function Composer.ReceiveOutcome(args)
    local state = ReceiveContext.Build(args)
    if not state then return false end
    local values = state.args
    if values.success ~= true then
        ReceivePresentation.Reject(state, values.reason)
        return false, values.reason
    end
    if not state.block or not state.session then
        ReceivePresentation.Reject(state, "block_unavailable")
        return false, "block_unavailable"
    end
    ReceivePresentation.AppendDiary(state)
    ReceiveContext.ProjectRelationship(state)
    ReceivePresentation.ApplyEffects(state)
    ReceivePresentation.Deliver(state)
    return true
end


return Composer
