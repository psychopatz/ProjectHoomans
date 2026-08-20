local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Registry = Conversation.Registry
local Internal = Composer.Internal

local activeView = Internal.ActiveView
local lifecycleState = Internal.LifecycleState
local notifyFailure = Internal.NotifyFailure
local requestID = Internal.RequestID
local sendRequest = Internal.SendRequest

function Composer.PumpLocalRequests()
    local requests = Composer.localRequests
    Composer.localRequests = {}
    for _, request in ipairs(requests) do
        if request.command == PNC.Const.CMD_CONVERSATION_CATEGORY_REQUEST
            and Conversation.Authority.HandleCategory
        then
            Conversation.Authority.HandleCategory(request.player, request.payload)
        elseif request.command == PNC.Const.CMD_CONVERSATION_CHOICE_REQUEST
            and Conversation.Authority.HandleChoice
        then
            Conversation.Authority.HandleChoice(request.player, request.payload)
        elseif request.command == PNC.Const.CMD_CONVERSATION_RECRUIT_REQUEST
            and Conversation.Authority.HandleRecruit
        then
            Conversation.Authority.HandleRecruit(request.player, request.payload)
        end
    end
end

function Composer.RequestCategory(npcID, categoryID, autoChoiceID)
    local view = activeView(npcID)
    local lifecycle = lifecycleState(view)
    if not view then return false, "conversation_not_ready" end
    if not lifecycle then
        notifyFailure(view, "status.block_unavailable", "conversation_not_ready")
        return false, "conversation_not_ready"
    end
    local id = requestID("category")
    view.spec.context.pendingConversationRequest = id
    view.spec.context.pendingConversationAutoChoice = autoChoiceID and {
        categoryID = categoryID,
        choiceID = autoChoiceID,
    } or nil
    local sent, reason = sendRequest(PNC.Const.CMD_CONVERSATION_CATEGORY_REQUEST, {
        requestID = id,
        npcID = tostring(npcID),
        token = lifecycle.token,
        categoryID = categoryID,
        registryFingerprint = Registry.GetFingerprint(),
    })
    if not sent then
        view.spec.context.pendingConversationRequest = nil
        view.spec.context.pendingConversationAutoChoice = nil
        notifyFailure(view, "status.block_unavailable", reason)
    end
    return sent, reason
end

function Composer.RequestChoice(npcID, blockID, nodeID, choiceID)
    local view = activeView(npcID)
    local lifecycle = lifecycleState(view)
    if not view then return false, "conversation_not_ready" end
    if not lifecycle then
        notifyFailure(view, "status.choice_rejected", "conversation_not_ready")
        return false, "conversation_not_ready"
    end
    local id = requestID("choice")
    view.spec.context.pendingConversationRequest = id
    local sent, reason = sendRequest(PNC.Const.CMD_CONVERSATION_CHOICE_REQUEST, {
        requestID = id,
        npcID = tostring(npcID),
        token = lifecycle.token,
        blockID = blockID,
        nodeID = nodeID,
        choiceID = choiceID,
        registryFingerprint = Registry.GetFingerprint(),
    })
    if not sent then
        view.spec.context.pendingConversationRequest = nil
        notifyFailure(view, "status.choice_rejected", reason)
    end
    return sent, reason
end

function Composer.RequestRecruit(npcID)
    local view = activeView(npcID)
    local lifecycle = lifecycleState(view)
    if not view then return false, "conversation_not_ready" end
    if not lifecycle then
        notifyFailure(view, "status.choice_rejected", "conversation_not_ready")
        return false, "conversation_not_ready"
    end
    local id = requestID("recruit")
    view.spec.context.pendingConversationRequest = id
    local sent, reason = sendRequest(
        PNC.Const.CMD_CONVERSATION_RECRUIT_REQUEST,
        {
            requestID = id,
            npcID = tostring(npcID),
            token = lifecycle.token,
            registryFingerprint = Registry.GetFingerprint(),
        }
    )
    if not sent then
        view.spec.context.pendingConversationRequest = nil
        notifyFailure(view, "status.choice_rejected", reason)
    end
    return sent, reason
end

return Composer

