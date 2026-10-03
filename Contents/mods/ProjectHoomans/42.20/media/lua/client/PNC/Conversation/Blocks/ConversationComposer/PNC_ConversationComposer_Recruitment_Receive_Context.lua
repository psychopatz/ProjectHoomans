-- Client-side recruitment result context and state projection boundary.

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal
local ReceiveContext = {}

local activeView = Internal.ActiveView
local receiveRelationshipAfter = Internal.ReceiveRelationshipAfter

function ReceiveContext.Build(args)
    args = type(args) == "table" and args or {}
    local view = activeView(args.npcID)
    if not view then return nil end
    if args.requestID ~= view.spec.context.pendingConversationRequest then
        return nil
    end
    view.spec.context.pendingConversationRequest = nil
    return {
        args = args,
        view = view,
        context = view.spec.context.conversationBlockContext,
        session = view.session,
    }
end

function ReceiveContext.ProjectRejected(state)
    local args = state.args
    local clientState = PNC.Network and PNC.Network.ClientState
    if clientState and args.relationshipDelta then
        clientState.lastConversationDelta = {
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
    state.view.spec.context.lastConversationError = tostring(
        args.reason or "recruitment_rejected"
    )
    if PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("Conversation recruitment rejected npc="
            .. tostring(args.npcID or "unknown") .. " reason="
            .. tostring(args.reason or "unknown"))
    end
end

function ReceiveContext.ProjectAccepted(state)
    local args = state.args
    state.view.spec.context.lastConversationRecruitment = {
        route = args.route,
        relationship = args.relationship,
        reason = args.reason,
    }
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
end

Internal.RecruitmentReceiveContext = ReceiveContext

return ReceiveContext
