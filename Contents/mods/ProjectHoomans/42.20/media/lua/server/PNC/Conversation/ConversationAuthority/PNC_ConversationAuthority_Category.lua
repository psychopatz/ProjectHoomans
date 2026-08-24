-- Server-authoritative conversation category selection.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local Registry = PNC.Conversation.Registry
local Selector = PNC.Conversation.Selector
local History = PNC.Conversation.History
local validateLease = Internal.ValidateLease
local requestIsCurrent = Internal.RequestIsCurrent
local send = Internal.Send

function Authority.HandleCategory(player, args)
    args = type(args) == "table" and args or {}
    if type(args.requestID) ~= "string" or args.requestID == "" then
        return false, "request_id_required"
    end
    local record = PNC.Registry.Get(args.npcID)
    local ok, reason, lease = validateLease(player, record, args.token)
    if not ok then
        send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
            requestID = args.requestID, success = false, reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
    end
    lease.processedConversationRequests =
        lease.processedConversationRequests or {}
    if lease.processedConversationRequests[args.requestID] then
        send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
            requestID = args.requestID,
            success = false,
            reason = "replayed_request",
            npcID = tostring(args.npcID or ""),
        })
        return false, "replayed_request"
    end
    if not requestIsCurrent(args) then
        send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
            requestID = args.requestID, success = false,
            reason = "registry_mismatch",
            npcID = tostring(args.npcID or ""),
            registryFingerprint = Registry.GetFingerprint(),
        })
        return false, "registry_mismatch"
    end
    local context
    context, reason = Authority.BuildContext(player, record, args.token)
    if not context then
        send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
            requestID = args.requestID,
            success = false,
            reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
    end
    local categoryEligible
    categoryEligible, reason = Selector.IsCategoryEligible(
        args.categoryID,
        context,
        args.categoryID == "projecthoomans:greetings"
            and context.audiences.hostile == true
    )
    if not categoryEligible then
        send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
            requestID = args.requestID,
            success = false,
            reason = reason,
            npcID = tostring(args.npcID or ""),
            categoryID = args.categoryID,
        })
        return false, reason
    end
    local categoryHistory = History.Get(
        "category:" .. tostring(args.categoryID or ""),
        { scope = "pair" },
        context
    )
    context.historySlot = categoryHistory and categoryHistory.useCount or 0
    local block, selection = Selector.SelectBlock(args.categoryID, context)
    if not block then
        send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
            requestID = args.requestID, success = false,
            reason = "no_eligible_block", categoryID = args.categoryID,
            npcID = tostring(args.npcID or ""),
        })
        return false, "no_eligible_block"
    end
    lease.conversationState = {
        blockID = block.id,
        nodeID = block.entryNode,
        categoryID = block.category,
        registryFingerprint = Registry.GetFingerprint(),
        processed = {},
    }
    lease.processedConversationRequests[args.requestID] = {
        kind = "category",
    }
    send(player, PNC.Const.CMD_CONVERSATION_BLOCK, {
        requestID = args.requestID,
        success = true,
        npcID = record.id,
        blockID = block.id,
        nodeID = block.entryNode,
        categoryID = block.category,
        registryFingerprint = Registry.GetFingerprint(),
        selection = selection,
    })
    return true, block.id
end

return Authority
