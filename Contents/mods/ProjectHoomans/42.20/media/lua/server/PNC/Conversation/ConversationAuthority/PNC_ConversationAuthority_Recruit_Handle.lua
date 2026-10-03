-- Server-authoritative recruitment coordinator.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local RecruitmentContext = Internal.RecruitHandleContext
local RecruitmentEffects = Internal.RecruitHandleEffects
local RecruitmentResponse = Internal.RecruitHandleResponse

if not RecruitmentContext or not RecruitmentEffects
    or not RecruitmentResponse
then
    return Authority
end

function Authority.HandleRecruit(player, args)
    local state = RecruitmentContext.Build(player, args)
    if state.silent then return false, state.reason end
    if state.reason then
        return RecruitmentResponse.Reject(state, state.reason)
    end
    RecruitmentEffects.Commit(state)
    if state.accepted then
        return RecruitmentResponse.Send(state)
    end
    return RecruitmentResponse.Reject(
        state,
        state.evaluationReason or "recruitment_rejected",
        state.details
    )
end

return Authority
