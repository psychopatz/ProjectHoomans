-- Client presentation for the authoritative departure warning branch.

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

local function returnToMenu(view, context)
    local session = view and view.session
    if not session then return end
    view.spec.nodes.menu = Composer.BuildMenuNode(
        context,
        context and context.conversationMenuOptions
    )
    session.pendingClose = false
    session.pendingCloseReason = nil
    session.pendingNext = "menu"
    if #session.queue == 0 then session:finishPending() end
end

function Composer.ReceiveDepartureOutcome(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcID)
    if not view then return false end
    if args.requestID ~= view.spec.context.pendingConversationRequest then
        return false
    end
    view.spec.context.pendingConversationRequest = nil
    local context = view.spec.context.conversationBlockContext
    local session = view.session
    if args.relationshipAfter then
        receiveRelationshipAfter(
            args.npcID,
            args.relationshipAfter,
            args.relationshipDelta,
            {
                source = "colonist_departure",
                eventID = args.eventID,
                revision = args.relationshipAfter.revision,
            }
        )
    end
    if args.warning == true then
        view.spec.context.pendingDepartureWarning = true
        if context then
            context.pendingDepartureWarning = true
            appendDiary(args.npcID, {
                kind = "colonist_departure",
                choiceID = "disband",
                npcText = resolvedDialogue(dialoguePayload(
                    SYSTEM_SOURCE,
                    args.responseKey or "response.departure.warning",
                    context
                )),
                departure = args.departure,
                reason = args.reason,
            })
        end
        if session then
            session:queueMessage("npc", dialoguePayload(
                SYSTEM_SOURCE,
                args.responseKey or "response.departure.warning",
                context
            ))
            returnToMenu(view, context)
        end
        return false, args.reason
    end
    view.spec.context.pendingDepartureWarning = nil
    if context then context.pendingDepartureWarning = nil end
    if args.success ~= true then
        view.spec.context.lastConversationError = tostring(
            args.reason or "departure_rejected"
        )
        if session and args.responseKey then
            session:queueMessage("npc", dialoguePayload(
                SYSTEM_SOURCE, args.responseKey, context,
                { reason = args.reason or "departure_rejected" }
            ))
            returnToMenu(view, context)
        else
            notifyFailure(view, "status.choice_rejected", args.reason)
        end
        return false, args.reason
    end
    if context then
        appendDiary(args.npcID, {
            kind = "colonist_departure",
            choiceID = "disband_confirm",
            npcText = resolvedDialogue(dialoguePayload(
                SYSTEM_SOURCE,
                args.responseKey or "response.departure.confirmed",
                context
            )),
            delta = args.relationshipDelta,
            before = args.relationshipBefore,
            after = args.relationshipAfter,
            reason = args.reason,
        })
    end
    if session then
        session:queueMessage("npc", dialoguePayload(
            SYSTEM_SOURCE,
            args.responseKey or "response.departure.confirmed",
            context
        ))
        session.pendingClose = true
        session.pendingCloseReason = args.closeReason or "colonist_departed"
        if #session.queue == 0 then session:finishPending() end
    end
    return true
end

return Composer
