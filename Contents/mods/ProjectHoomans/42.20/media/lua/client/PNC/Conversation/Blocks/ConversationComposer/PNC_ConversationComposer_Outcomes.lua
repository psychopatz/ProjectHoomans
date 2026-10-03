local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal

local Registry = Conversation.Registry
local activeView = Internal.ActiveView
local conversationDebugEnabled = Internal.ConversationDebugEnabled
local notifyFailure = Internal.NotifyFailure
local rememberCategoryUse = Internal.RememberCategoryUse
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

require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Outcomes_Receive_Context"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Outcomes_Receive_Presentation"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Outcomes_Receive"

return Composer
