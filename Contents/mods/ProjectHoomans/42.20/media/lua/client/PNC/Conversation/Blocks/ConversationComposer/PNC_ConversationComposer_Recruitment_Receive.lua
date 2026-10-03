-- Client-side recruitment result coordinator.

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal
local ReceiveContext = Internal.RecruitmentReceiveContext
local ReceivePresentation = Internal.RecruitmentReceivePresentation

if not ReceiveContext or not ReceivePresentation then return Composer end

function Composer.ReceiveRecruitOutcome(args)
    local state = ReceiveContext.Build(args)
    if not state then return false end
    if state.args.success ~= true then
        ReceiveContext.ProjectRejected(state)
        ReceivePresentation.AppendRejected(state)
        return false, state.args.reason
    end
    ReceiveContext.ProjectAccepted(state)
    ReceivePresentation.AppendAccepted(state)
    return true
end

return Composer
