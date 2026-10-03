-- Client-side recruitment result response and presentation boundary.

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal
local Presentation = {}

local SYSTEM_SOURCE = Internal.SYSTEM_SOURCE
local appendDiary = Internal.AppendDiary
local dialoguePayload = Internal.DialoguePayload
local notifyFailure = Internal.NotifyFailure
local portraitAnimationForReaction = Internal.PortraitAnimationForReaction
local resolvedDialogue = Internal.ResolvedDialogue

local function rejectedReplyPayload(args, context)
    return dialoguePayload(
        SYSTEM_SOURCE,
        args.responseKey,
        context,
        { route = args.route or "none" }
    )
end

local function acceptedReplyPayload(args, context)
    return dialoguePayload(
        SYSTEM_SOURCE,
        args.responseKey or "response.recruit.admire.1",
        context,
        { route = args.route or "admire" }
    )
end

function Presentation.AppendRejected(state)
    local args = state.args
    local session = state.session
    local context = state.context
    appendDiary(args.npcID, {
        kind = "recruitment",
        choiceID = "recruit",
        playerText = resolvedDialogue(dialoguePayload(
            SYSTEM_SOURCE,
            "choice.recruit",
            context
        )),
        npcText = resolvedDialogue(rejectedReplyPayload(args, context)),
        delta = args.relationshipDelta,
        before = args.relationshipBefore,
        after = args.relationshipAfter,
        recruitment = args.relationship,
        reason = args.reason,
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    })
    if session then
        if args.responseKey then
            session:queueMessage(
                "npc",
                rejectedReplyPayload(args, context),
                { portraitAnimation = portraitAnimationForReaction(
                    args.npcReaction
                ) }
            )
            state.view.spec.nodes.menu = Composer.BuildMenuNode(
                context,
                context and context.conversationMenuOptions
            )
            session.pendingClose = false
            session.pendingCloseReason = nil
            session.pendingNext = "menu"
            if #session.queue == 0 then session:finishPending() end
        else
            notifyFailure(state.view, "status.choice_rejected", args.reason)
        end
    else
        notifyFailure(state.view, "status.choice_rejected", args.reason)
    end
end

function Presentation.AppendAccepted(state)
    local args = state.args
    local context = state.context
    appendDiary(args.npcID, {
        kind = "recruitment",
        choiceID = "recruit",
        playerText = resolvedDialogue(dialoguePayload(
            SYSTEM_SOURCE, "choice.recruit", context
        )),
        npcText = resolvedDialogue(acceptedReplyPayload(args, context)),
        delta = args.relationshipDelta,
        before = args.relationshipBefore,
        after = args.relationshipAfter,
        recruitment = args.relationship,
        reason = args.reason,
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    })
    local session = state.session
    if session then
        session:queueMessage(
            "npc",
            acceptedReplyPayload(args, context),
            { portraitAnimation = portraitAnimationForReaction(
                args.npcReaction
            ) }
        )
        session.pendingClose = true
        session.pendingCloseReason = args.closeReason or "recruited"
        if #session.queue == 0 then session:finishPending() end
    end
end

Internal.RecruitmentReceivePresentation = Presentation

return Presentation
