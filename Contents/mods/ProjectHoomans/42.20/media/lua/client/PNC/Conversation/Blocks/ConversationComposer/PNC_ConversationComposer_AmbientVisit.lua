local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal

local SYSTEM_SOURCE = Internal.SYSTEM_SOURCE
local VISIT_SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/greetings/ambient_visit/{language}/arrival.json",
    domain = "pnc.greetings.ambient_visit.arrival",
}
local activeView = Internal.ActiveView
local appendDiary = Internal.AppendDiary
local dialoguePayload = Internal.DialoguePayload
local notifyFailure = Internal.NotifyFailure
local portraitAnimationForReaction = Internal.PortraitAnimationForReaction
local resolvedDialogue = Internal.ResolvedDialogue

function Composer.ReceiveAmbientVisitOutcome(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcID)
    if not view then return false end
    if args.requestID ~= view.spec.context.pendingConversationRequest then
        return false
    end
    view.spec.context.pendingConversationRequest = nil
    if args.success ~= true then
        view.spec.context.lastConversationError = tostring(
            args.reason or "ambient_visit_rejected"
        )
        notifyFailure(view, "status.choice_rejected", args.reason)
        return false, args.reason
    end
    local context = view.spec.context.conversationBlockContext
    appendDiary(args.npcID, {
        kind = "ambient_visit",
        choiceID = "ambient_visit",
        playerText = resolvedDialogue(dialoguePayload(
            SYSTEM_SOURCE,
            "choice.ambient_visit",
            context
        )),
        npcText = resolvedDialogue(dialoguePayload(
            VISIT_SOURCE,
            args.responseKey or "response.ambient_visit.accepted.1",
            context
        )),
        visit = args.visit,
        reason = args.reason,
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    })
    local session = view.session
    if session then
        session:queueMessage("npc", dialoguePayload(
            VISIT_SOURCE,
            args.responseKey or "response.ambient_visit.accepted.1",
            context
        ), {
            portraitAnimation = portraitAnimationForReaction(
                args.npcReaction
            ),
        })
        session.pendingClose = true
        session.pendingCloseReason = args.closeReason
            or "ambient_visit_started"
        if #session.queue == 0 then session:finishPending() end
    end
    if PNC.Client and PNC.Client.RequestConversationRelationship then
        PNC.Client.RequestConversationRelationship(args.npcID)
    end
    return true
end

return Composer
