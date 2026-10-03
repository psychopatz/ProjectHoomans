-- Client-side conversation outcome response and presentation boundary.

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal
local Presentation = {}

local appendDiary = Internal.AppendDiary
local dialoguePayload = Internal.DialoguePayload
local lifecycleState = Internal.LifecycleState
local notifyFailure = Internal.NotifyFailure
local portraitAnimationForReaction = Internal.PortraitAnimationForReaction
local resolvedDialogue = Internal.ResolvedDialogue

function Presentation.Reject(state, reason)
    notifyFailure(state.view, "status.choice_rejected", reason)
end

function Presentation.AppendDiary(state)
    local args = state.args
    local block = state.block
    local context = state.context
    state.playerPayload = state.choice and dialoguePayload(
        block.textSource,
        state.choice.textKey,
        context
    ) or nil
    state.npcPayload = args.responseKey and dialoguePayload(
        block.textSource,
        args.responseKey,
        context
    ) or nil
    appendDiary(args.npcID, {
        kind = "conversation",
        categoryID = block.category,
        blockID = args.blockID,
        nodeID = state.nodeID,
        choiceID = args.choiceID,
        outcomeID = args.outcomeID,
        playerText = resolvedDialogue(state.playerPayload),
        npcText = resolvedDialogue(state.npcPayload),
        delta = args.relationshipDelta,
        before = args.relationshipBefore,
        after = args.relationshipAfter,
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    })
end

function Presentation.ApplyEffects(state)
    for _, effect in ipairs(state.args.effectResults or {}) do
        if effect.type == "pnc:open_territory_claim"
            and effect.result and effect.result.openClaim == true
        then
            if PNC.CommandHub and PNC.CommandHub.OpenTerritorySetup then
                PNC.CommandHub.OpenTerritorySetup()
            elseif PNC.Core and PNC.Core.LogWarn then
                PNC.Core.LogWarn(
                    "Set Territory outcome received before Command Hub loaded"
                )
            end
        end
    end
end

function Presentation.Deliver(state)
    local args = state.args
    local context = state.context
    local session = state.session
    if args.responseKey then
        session:queueMessage("npc", state.npcPayload, {
            portraitAnimation = portraitAnimationForReaction(
                args.npcReaction
            ),
        })
    end
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(table.concat({
            "Conversation outcome",
            "npc=" .. tostring(args.npcID or "unknown"),
            "block=" .. tostring(args.blockID or "unknown"),
            "choice=" .. tostring(args.choiceID or "unknown"),
            "outcome=" .. tostring(args.outcomeID or "unknown"),
            "next=" .. tostring(args.nextNodeID or "none"),
            "close=" .. tostring(args.close == true),
            "reason=" .. tostring(args.closeReason or "continued"),
        }, " "))
    end
    session.pendingClose = args.close == true
    session.pendingCloseReason = args.closeReason
    if args.nextNodeID == "$root" then
        if context.giftConversationActive
            and PNC.InventoryWindow
            and PNC.InventoryWindow.Close
        then
            PNC.InventoryWindow.Close()
            context.giftConversationActive = nil
        end
        state.view.spec.nodes.menu = Composer.BuildMenuNode(
            context,
            context.conversationMenuOptions
        )
        session.pendingNext = "menu"
    else
        session.pendingNext = args.nextNodeID
            and "block:" .. tostring(args.nextNodeID) or nil
        if args.nextNodeID == "gift"
            and PNC.InventoryWindow
            and PNC.InventoryWindow.Open
        then
            local lifecycle = lifecycleState(state.view)
            context.giftConversationActive = true
            PNC.InventoryWindow.Open(args.npcID, {
                mode = "gift",
                token = lifecycle and lifecycle.token,
            })
        end
    end
    if #session.queue == 0 then session:finishPending() end
end

Internal.OutcomeReceivePresentation = Presentation

return Presentation
