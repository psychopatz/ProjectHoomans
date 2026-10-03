-- Client-side conversation outcome request and authoritative state boundary.

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal
local Registry = Conversation.Registry
local Selector = Conversation.Selector
local ReceiveContext = {}

local activeView = Internal.ActiveView
local receiveRelationshipAfter = Internal.ReceiveRelationshipAfter
local rememberCategoryUse = Internal.RememberCategoryUse

function ReceiveContext.Build(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcID)
    if not view or not view.spec or not view.spec.context then return nil end

    local contextRoot = view.spec.context
    if args.requestID ~= contextRoot.pendingConversationRequest then
        return nil
    end
    contextRoot.pendingConversationRequest = nil

    local state = {
        args = args,
        view = view,
        context = contextRoot.conversationBlockContext,
        session = view.session,
    }
    if args.success ~= true then return state end

    state.block = Registry.GetBlock(args.blockID)
    if not state.block or not state.session then return state end

    rememberCategoryUse(state.context, state.block.category, args.outcomeID)
    state.nodeID = args.nodeID or state.block.entryNode
    state.choice = Selector.GetChoice(
        state.block,
        state.nodeID,
        args.choiceID
    )
    return state
end

function ReceiveContext.ProjectRelationship(state)
    local args = state.args
    receiveRelationshipAfter(
        args.npcID,
        args.relationshipAfter,
        args.relationshipDelta,
        {
            source = "conversation_outcome",
            eventID = args.eventID,
            revision = args.relationshipAfter
                and args.relationshipAfter.revision,
        }
    )
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
end

Internal.OutcomeReceiveContext = ReceiveContext

return ReceiveContext
