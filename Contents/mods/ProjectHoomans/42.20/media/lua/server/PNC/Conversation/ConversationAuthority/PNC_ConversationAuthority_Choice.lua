-- Server-authoritative conversation choice resolution.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.Authority = PNC.Conversation.Authority or {}
local Authority = PNC.Conversation.Authority
local Internal = Authority.Internal
local Registry = PNC.Conversation.Registry
local Selector = PNC.Conversation.Selector
local Rules = PNC.Conversation.Rules
local History = PNC.Conversation.History
local validateLease = Internal.ValidateLease
local requestIsCurrent = Internal.RequestIsCurrent
local send = Internal.Send
local relationshipCopy = Internal.RelationshipCopy
local relationshipDelta = Internal.RelationshipDelta
local personalRelationshipQueries = Internal.PersonalRelationshipQueries

function Authority.HandleChoice(player, args)
    args = type(args) == "table" and args or {}
    if type(args.requestID) ~= "string" or args.requestID == "" then
        return false, "request_id_required"
    end
    local record = PNC.Registry.Get(args.npcID)
    local ok, reason, lease = validateLease(player, record, args.token)
    if lease and lease.processedConversationRequests
        and lease.processedConversationRequests[args.requestID]
    then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID,
            success = false,
            reason = "replayed_request",
            npcID = tostring(args.npcID or ""),
        })
        return false, "replayed_request"
    end
    local state = lease and lease.conversationState or nil
    if not ok or not state then reason = reason or "conversation_state_missing" end
    if ok and (not requestIsCurrent(args)
        or state.registryFingerprint ~= Registry.GetFingerprint())
    then ok, reason = false, "registry_mismatch" end
    if ok and (state.blockID ~= args.blockID or state.nodeID ~= args.nodeID) then
        ok, reason = false, "stale_node"
    end
    if not ok then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID, success = false, reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
    end
    local block = Registry.GetBlock(state.blockID)
    local choice = Selector.GetChoice(block, state.nodeID, args.choiceID)
    local context
    context, reason = Authority.BuildContext(player, record, args.token)
    if not context then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID,
            success = false,
            reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
    end
    context.blockID = block and block.id
    context.choiceID = choice and choice.id
    local eligible
    eligible, reason = Selector.IsChoiceEligible(
        block, state.nodeID, choice, context
    )
    if not eligible then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID, success = false, reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
    end
    local subjectID = table.concat({ block.id, state.nodeID, choice.id }, "/")
    context.historySlot = (History.Get(subjectID, choice["repeat"], context)
        or { useCount = 0 }).useCount or 0
    local outcome = Selector.SelectOutcome(block, state.nodeID, choice, context)
    if not outcome then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID,
            success = false,
            reason = "no_eligible_outcome",
            npcID = tostring(args.npcID or ""),
        })
        return false, "no_eligible_outcome"
    end
    context.outcomeID = outcome.id
    local relationshipBefore = relationshipCopy(context.relationship)
    local effectResults
    ok, reason = Rules.ValidateEffects(outcome.effects, context)
    if ok then ok, reason, effectResults = Rules.ApplyEffects(outcome.effects, context) end
    if not ok then
        send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, {
            requestID = args.requestID, success = false, reason = reason,
            npcID = tostring(args.npcID or ""),
        })
        return false, reason
    end
    local relationshipAfter = relationshipBefore
    local relationshipQueries = personalRelationshipQueries()
    if relationshipQueries and relationshipQueries.Get then
        relationshipAfter = relationshipCopy(relationshipQueries.Get(
            record.id, context.playerEntityKey
        ))
    end
    History.Commit(block.id, block["repeat"], context, outcome.id)
    History.Commit(subjectID, choice["repeat"], context, outcome.id)
    History.Commit(
        "category:" .. tostring(state.categoryID),
        { scope = "pair" },
        context,
        outcome.id
    )
    state.nodeID = outcome.next
    local payload = {
        requestID = args.requestID,
        success = true,
        npcID = record.id,
        blockID = block.id,
        nodeID = args.nodeID,
        choiceID = choice.id,
        outcomeID = outcome.id,
        responseKey = outcome.responseKey,
        nextNodeID = outcome.next,
        close = outcome.close == true,
        closeReason = outcome.close == true and table.concat({
            "authored_outcome", block.id, state.nodeID, choice.id, outcome.id,
        }, ":") or nil,
        relationshipBefore = relationshipBefore,
        relationshipAfter = relationshipAfter,
        relationshipDelta = relationshipDelta(
            relationshipBefore, relationshipAfter
        ),
        effectResults = effectResults,
        registryFingerprint = Registry.GetFingerprint(),
    }
    state.processed[args.requestID] = payload
    lease.processedConversationRequests = lease.processedConversationRequests or {}
    lease.processedConversationRequests[args.requestID] = payload
    send(player, PNC.Const.CMD_CONVERSATION_OUTCOME, payload)
    if payload.close then lease.conversationState = nil end
    return true, outcome.id
end

return Authority
