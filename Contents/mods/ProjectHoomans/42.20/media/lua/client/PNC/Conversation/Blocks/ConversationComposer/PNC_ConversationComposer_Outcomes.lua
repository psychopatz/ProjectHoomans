local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Registry = Conversation.Registry
local Selector = Conversation.Selector
local Internal = Composer.Internal

local activeView = Internal.ActiveView
local appendDiary = Internal.AppendDiary
local conversationDebugEnabled = Internal.ConversationDebugEnabled
local dialoguePayload = Internal.DialoguePayload
local lifecycleState = Internal.LifecycleState
local notifyFailure = Internal.NotifyFailure
local receiveRelationshipAfter = Internal.ReceiveRelationshipAfter
local rememberCategoryUse = Internal.RememberCategoryUse
local resolvedDialogue = Internal.ResolvedDialogue
local restoreCurrentChoices = Internal.RestoreCurrentChoices

function Composer.ReceiveBlock(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcID)
    if not view then return false end
    if args.requestID ~= view.spec.context.pendingConversationRequest then
        return false
    end
    view.spec.context.pendingConversationRequest = nil
    if args.success ~= true then
        if args.reason == "once_per_day_used" and args.categoryID then
            local context = view.spec.context.conversationBlockContext
            rememberCategoryUse(context, args.categoryID)
            view.spec.nodes.menu = Composer.BuildMenuNode(
                context,
                context and context.conversationMenuOptions
            )
            if view.session and view.session.currentNodeID == "menu" then
                view.session.currentNode = view.spec.nodes.menu
            end
            -- Hide an expected stale-history rejection locally.
            if PNC.Core and PNC.Core.LogInfo then
                PNC.Core.LogInfo("Conversation category hidden after server daily limit npc="
                    .. tostring(args.npcID or "unknown") .. " category="
                    .. tostring(args.categoryID) .. " debug="
                    .. tostring(conversationDebugEnabled()))
            end
            restoreCurrentChoices(view)
            return false, args.reason
        end
        notifyFailure(view, "status.block_unavailable", args.reason)
        return false, args.reason
    end
    local block = Registry.GetBlock(args.blockID)
    local context = view.spec.context.conversationBlockContext
    if not block or not context then
        notifyFailure(view, "status.block_unavailable", "block_unavailable")
        return false, "block_unavailable"
    end
    local attached, nodeID = Composer.AttachBlock(view.spec, block, context)
    if not attached then
        notifyFailure(view, "status.block_unavailable", nodeID)
        return false, nodeID
    end
    local automatic = view.spec.context.pendingConversationAutoChoice
    view.spec.context.pendingConversationAutoChoice = nil
    if automatic and automatic.categoryID == args.categoryID then
        return Composer.RequestChoice(
            args.npcID,
            block.id,
            args.nodeID or block.entryNode,
            automatic.choiceID
        )
    end
    view.session.spec = view.spec
    view.session:enterNode("block:" .. tostring(args.nodeID or block.entryNode))
    return true
end

function Composer.ReceiveOutcome(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcID)
    if not view then return false end
    if args.requestID ~= view.spec.context.pendingConversationRequest then
        return false
    end
    view.spec.context.pendingConversationRequest = nil
    local session = view.session
    if args.success ~= true then
        notifyFailure(view, "status.choice_rejected", args.reason)
        return false, args.reason
    end
    local block = Registry.GetBlock(args.blockID)
    if not block or not session then
        notifyFailure(view, "status.choice_rejected", "block_unavailable")
        return false, "block_unavailable"
    end
    local context = view.spec.context.conversationBlockContext
    rememberCategoryUse(context, block.category, args.outcomeID)
    local nodeID = args.nodeID or block.entryNode
    local choice = Selector.GetChoice(block, nodeID, args.choiceID)
    local playerPayload = choice and dialoguePayload(
        block.textSource,
        choice.textKey,
        context
    ) or nil
    local npcPayload = args.responseKey and dialoguePayload(
        block.textSource,
        args.responseKey,
        context
    ) or nil
    appendDiary(args.npcID, {
        kind = "conversation",
        categoryID = block.category,
        blockID = args.blockID,
        nodeID = nodeID,
        choiceID = args.choiceID,
        outcomeID = args.outcomeID,
        playerText = resolvedDialogue(playerPayload),
        npcText = resolvedDialogue(npcPayload),
        delta = args.relationshipDelta,
        before = args.relationshipBefore,
        after = args.relationshipAfter,
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    })
    receiveRelationshipAfter(args.npcID, args.relationshipAfter)
    for _, effect in ipairs(args.effectResults or {}) do
        if effect.type == "pnc:open_territory_claim"
            and effect.result and effect.result.openClaim == true
            and PNC.ColonyManagementUI
            and PNC.ColonyManagementUI.OpenClaimTerritory
        then
            PNC.ColonyManagementUI.OpenClaimTerritory()
        end
    end
    local clientState = PNC.Network and PNC.Network.ClientState
    if args.relationshipDelta and clientState then
        clientState.lastConversationDelta = {
            npcID = args.npcID,
            source = "conversation",
            blockID = args.blockID,
            choiceID = args.choiceID,
            outcomeID = args.outcomeID,
            delta = args.relationshipDelta,
            before = args.relationshipBefore,
            after = args.relationshipAfter,
            effects = args.effectResults,
            at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
        }
    end
    if args.responseKey then
        session:queueMessage("npc", dialoguePayload(
            block.textSource,
            args.responseKey,
            context
        ))
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
        view.spec.nodes.menu = Composer.BuildMenuNode(
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
            local lifecycle = lifecycleState(view)
            context.giftConversationActive = true
            PNC.InventoryWindow.Open(args.npcID, {
                mode = "gift",
                token = lifecycle and lifecycle.token,
            })
        end
    end
    if #session.queue == 0 then session:finishPending() end
    return true
end

return Composer
