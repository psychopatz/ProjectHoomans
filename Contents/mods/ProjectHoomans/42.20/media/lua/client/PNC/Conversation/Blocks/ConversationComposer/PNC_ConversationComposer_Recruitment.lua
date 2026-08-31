local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal

local SYSTEM_SOURCE = Internal.SYSTEM_SOURCE
local activeView = Internal.ActiveView
local appendDiary = Internal.AppendDiary
local dialoguePayload = Internal.DialoguePayload
local notifyFailure = Internal.NotifyFailure
local receiveRelationshipAfter = Internal.ReceiveRelationshipAfter
local resolvedDialogue = Internal.ResolvedDialogue

function Composer.ReceiveRecruitOutcome(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcID)
    if not view then return false end
    if args.requestID ~= view.spec.context.pendingConversationRequest then
        return false
    end
    view.spec.context.pendingConversationRequest = nil
    if args.success ~= true then
        local state = PNC.Network and PNC.Network.ClientState
        if state and args.relationshipDelta then
            state.lastConversationDelta = {
                npcID = args.npcID,
                source = "recruitment_rejected",
                delta = args.relationshipDelta,
                before = args.relationshipBefore,
                after = args.relationshipAfter,
                at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
            }
        end
        receiveRelationshipAfter(
            args.npcID,
            args.relationshipAfter,
            args.relationshipDelta,
            {
                source = "recruitment_rejected",
                eventID = args.eventID,
                revision = args.relationshipAfter
                    and args.relationshipAfter.revision,
            }
        )
        view.spec.context.lastConversationError = tostring(
            args.reason or "recruitment_rejected"
        )
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("Conversation recruitment rejected npc="
                .. tostring(args.npcID or "unknown") .. " reason="
                .. tostring(args.reason or "unknown"))
        end
        local session = view.session
        local context = view.spec.context.conversationBlockContext
        if context then
            appendDiary(args.npcID, {
                kind = "recruitment",
                choiceID = "recruit",
                playerText = resolvedDialogue(dialoguePayload(
                    SYSTEM_SOURCE, "choice.recruit", context
                )),
                npcText = args.responseKey and resolvedDialogue(dialoguePayload(
                    SYSTEM_SOURCE,
                    args.responseKey,
                    context,
                    { route = args.route or "none" }
                )) or nil,
                delta = args.relationshipDelta,
                before = args.relationshipBefore,
                after = args.relationshipAfter,
                recruitment = args.recruitment,
                reason = args.reason,
                at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
            })
        end
        if session and args.responseKey then
            session:queueMessage("npc", dialoguePayload(
                SYSTEM_SOURCE,
                args.responseKey,
                context,
                { route = args.route or "none" }
            ))
            view.spec.nodes.menu = Composer.BuildMenuNode(
                context,
                context and context.conversationMenuOptions
            )
            session.pendingClose = false
            session.pendingCloseReason = nil
            session.pendingNext = "menu"
            if #session.queue == 0 then session:finishPending() end
        else
            notifyFailure(view, "status.choice_rejected", args.reason)
        end
        return false, args.reason
    end
    local context = view.spec.context.conversationBlockContext
    view.spec.context.lastConversationRecruitment = {
        route = args.route,
        relationship = args.relationship,
        reason = args.reason,
    }
    appendDiary(args.npcID, {
        kind = "recruitment",
        choiceID = "recruit",
        playerText = resolvedDialogue(dialoguePayload(
            SYSTEM_SOURCE, "choice.recruit", context
        )),
        npcText = resolvedDialogue(dialoguePayload(
            SYSTEM_SOURCE,
            args.responseKey or "response.recruit.admire.1",
            context,
            { route = args.route or "admire" }
        )),
        delta = args.relationshipDelta,
        before = args.relationshipBefore,
        after = args.relationshipAfter,
        recruitment = args.relationship,
        reason = args.reason,
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    })
    receiveRelationshipAfter(
        args.npcID,
        args.relationshipAfter,
        args.relationshipDelta,
        {
            source = "recruitment",
            eventID = args.eventID,
            revision = args.relationshipAfter
                and args.relationshipAfter.revision,
        }
    )
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo("Conversation recruitment committed npc="
            .. tostring(args.npcID or "unknown") .. " route="
            .. tostring(args.route or "unknown"))
    end
    local session = view.session
    if session then
        session:queueMessage("npc", dialoguePayload(
            SYSTEM_SOURCE, args.responseKey or "response.recruit.admire.1", context,
            { route = args.route or "admire" }
        ))
        session.pendingClose = true
        session.pendingCloseReason = args.closeReason or "recruited"
        if #session.queue == 0 then session:finishPending() end
    end
    return true
end

return Composer
