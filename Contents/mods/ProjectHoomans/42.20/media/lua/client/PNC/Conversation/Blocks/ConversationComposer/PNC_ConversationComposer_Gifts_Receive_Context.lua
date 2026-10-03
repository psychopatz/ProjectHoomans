-- Client-side semantic gift result context and authoritative state boundary.

local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal
local ReceiveContext = {}

local GiftLifecycle = PNC.Semantics and PNC.Semantics.GiftLifecycle
local GiftContext = PNC.Semantics and PNC.Semantics.GiftContext

function ReceiveContext.Build(args)
    args = type(args) == "table" and args or {}
    local view = Internal.ActiveView(args.npcId)
    if not view then return nil end

    local rootContext = view.spec and view.spec.context or nil
    local context = rootContext and rootContext.conversationBlockContext
        or rootContext
    local session = view.session
    local requestID = tostring(args.requestId or "")
    if session and requestID ~= ""
        and GiftLifecycle and type(GiftLifecycle.IsHandled) == "function"
        and GiftLifecycle.IsHandled(session, requestID)
    then
        if PNC.Core and PNC.Core.LogInfo then
            PNC.Core.LogInfo("Conversation gift result ignored duplicate npc="
                .. tostring(args.npcId or "unknown") .. " request="
                .. requestID)
        end
        return nil, "gift_result_duplicate", true
    end

    local pending = session and GiftLifecycle
        and type(GiftLifecycle.Get) == "function"
        and GiftLifecycle.Get(session, requestID) or nil
    if not pending and session and session.semanticGiftRequests then
        -- Compatibility with a request created by an older hot-reloaded
        -- client before the lifecycle spoke was installed.
        pending = session.semanticGiftRequests[requestID]
    end

    local group = view.groupConversation
    local responseSession = group and group.closed ~= true
        and type(group.PrimarySession) == "function"
        and group:PrimarySession() or session
    local state = {
        args = args,
        view = view,
        rootContext = rootContext,
        context = context,
        session = session,
        requestID = requestID,
        pending = pending,
        responseSession = responseSession,
        semanticAuto = pending and pending.mode == "auto",
    }

    if session and requestID ~= "" and GiftLifecycle
        and type(GiftLifecycle.MarkHandled) == "function"
    then
        GiftLifecycle.MarkHandled(session, requestID)
    elseif pending and session and session.semanticGiftRequests then
        session.semanticGiftRequests[requestID] = nil
    end

    local clientInternal = PNC.Client and PNC.Client.Internal
    if args.knowledgeSnapshot and clientInternal
        and clientInternal.ApplyNPCKnowledgeSnapshot
    then
        clientInternal.ApplyNPCKnowledgeSnapshot(
            args.knowledgeSnapshot, "gift_reaction"
        )
    end

    local clientState = PNC.Network and PNC.Network.ClientState
    if args.relationshipDelta and clientState then
        clientState.lastConversationDelta = {
            npcID = args.npcId,
            source = "gift",
            delta = args.relationshipDelta,
            before = args.relationshipBefore,
            after = args.relationshipAfter,
            effects = args.giftEffect,
            itemTypes = args.itemTypes,
            at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
        }
    end

    return state
end

function ReceiveContext.ClearConversationState(state, automaticOnly)
    if automaticOnly and not state.semanticAuto then return end
    if state.context then state.context.giftConversationActive = nil end
    if state.rootContext then
        state.rootContext.giftConversationActive = nil
    end
end

function ReceiveContext.RecordTransfer(state)
    if not GiftContext or type(GiftContext.RecordTransfer) ~= "function" then
        return true
    end
    local recorded, contextReason = GiftContext.RecordTransfer(
        state.view, state.args, state.pending)
    if not recorded and PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("Conversation gift context not recorded npc="
            .. tostring(state.args.npcId or "unknown") .. " reason="
            .. tostring(contextReason or "unknown"))
    end
    return recorded, contextReason
end

Internal.GiftReceiveContext = ReceiveContext

return ReceiveContext
