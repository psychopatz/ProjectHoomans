local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal

local SYSTEM_SOURCE = Internal.SYSTEM_SOURCE
local ADMISSION_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/greetings/settlement_admission/{language}/arrival.json",
    domain = "pnc.greetings.settlement_admission.arrival",
}
local activeView = Internal.ActiveView
local appendDiary = Internal.AppendDiary
local dialoguePayload = Internal.DialoguePayload
local notifyFailure = Internal.NotifyFailure
local portraitAnimationForReaction = Internal.PortraitAnimationForReaction
local resolvedDialogue = Internal.ResolvedDialogue

function Composer.PumpSettlementVisitExpiry()
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local view = conversation and conversation.instance or nil
    local context = view and view.spec and view.spec.context
        and view.spec.context.conversationBlockContext or nil
    local visit = context and context.settlementVisit or nil
    local at = getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
        and tonumber(getGameTime():getWorldAgeHours()) or 0
    if not visit or visit.active ~= true
        or (tonumber(visit.expiresAt) or 0) > at
    then
        return false
    end
    local relationship = Conversation.Relationship
    local summary = relationship and relationship.GetPresentation
        and relationship.GetPresentation(context.npcID) or nil
    if summary and relationship.ReceivePresentation then
        summary.settlementVisit = nil
        relationship.ReceivePresentation(summary, nil, {
            source = "settlement_visit_expired_local",
        })
    end
    if PNC.Client and PNC.Client.RequestConversationRelationship then
        PNC.Client.RequestConversationRelationship(context.npcID)
    end
    return true
end

function Composer.ReceiveSettlementAdmissionOutcome(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcID)
    if not view then return false end
    if args.requestID ~= view.spec.context.pendingConversationRequest then
        return false
    end
    view.spec.context.pendingConversationRequest = nil
    if args.success ~= true then
        view.spec.context.lastConversationError = tostring(
            args.reason or "settlement_admission_rejected"
        )
        if PNC.Client and PNC.Client.RequestConversationRelationship then
            PNC.Client.RequestConversationRelationship(args.npcID)
        end
        notifyFailure(view, "status.choice_rejected", args.reason)
        return false, args.reason
    end
    local context = view.spec.context.conversationBlockContext
    appendDiary(args.npcID, {
        kind = "settlement_admission",
        choiceID = "settlement_admission",
        playerText = resolvedDialogue(dialoguePayload(
            SYSTEM_SOURCE,
            "choice.settlement_admission",
            context
        )),
        npcText = resolvedDialogue(dialoguePayload(
            ADMISSION_SOURCE,
            args.responseKey or "response.settlement_admission.accepted.1",
            context
        )),
        admission = args.admission,
        reason = args.reason,
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    })
    local session = view.session
    if session then
        session:queueMessage("npc", dialoguePayload(
            ADMISSION_SOURCE,
            args.responseKey or "response.settlement_admission.accepted.1",
            context
        ), {
            portraitAnimation = portraitAnimationForReaction(
                args.npcReaction
            ),
        })
        session.pendingClose = true
        session.pendingCloseReason = args.closeReason
            or "settlement_member_admitted"
        if #session.queue == 0 then session:finishPending() end
    end
    return true
end

return Composer
