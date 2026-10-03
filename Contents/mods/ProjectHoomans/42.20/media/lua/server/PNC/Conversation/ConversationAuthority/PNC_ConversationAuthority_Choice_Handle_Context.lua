-- Server-side conversation choice request and outcome selection boundary.

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
local ChoiceContext = {}

local validateLease = Internal.ValidateLease
local requestIsCurrent = Internal.RequestIsCurrent

local function rejected(state, reason)
    state.reason = reason
    return state
end

function ChoiceContext.Build(player, args)
    args = type(args) == "table" and args or {}
    local state = {
        player = player,
        args = args,
        record = PNC.Registry.Get(args.npcID),
    }
    if type(args.requestID) ~= "string" or args.requestID == "" then
        state.silent = true
        return rejected(state, "request_id_required")
    end

    local ok, reason, lease = validateLease(
        player,
        state.record,
        args.token
    )
    state.lease = lease
    if lease and lease.processedConversationRequests
        and lease.processedConversationRequests[args.requestID]
    then
        return rejected(state, "replayed_request")
    end
    if not ok then reason = reason or "conversation_state_missing" end
    state.conversationState = lease and lease.conversationState or nil
    if not state.conversationState then
        return rejected(state, "conversation_state_missing")
    end
    if not ok then return rejected(state, reason) end

    if not requestIsCurrent(args)
        or state.conversationState.registryFingerprint
            ~= Registry.GetFingerprint()
    then
        return rejected(state, "registry_mismatch")
    end
    if state.conversationState.blockID ~= args.blockID
        or state.conversationState.nodeID ~= args.nodeID
    then
        return rejected(state, "stale_node")
    end

    state.block = Registry.GetBlock(state.conversationState.blockID)
    state.choice = Selector.GetChoice(
        state.block,
        state.conversationState.nodeID,
        args.choiceID
    )
    local context
    context, reason = Authority.BuildContext(
        player,
        state.record,
        args.token
    )
    if not context then return rejected(state, reason) end
    context.blockID = state.block and state.block.id
    context.choiceID = state.choice and state.choice.id
    local eligible
    eligible, reason = Selector.IsChoiceEligible(
        state.block,
        state.conversationState.nodeID,
        state.choice,
        context
    )
    if not eligible then return rejected(state, reason) end

    state.context = context
    state.subjectID = table.concat({
        state.block.id,
        state.conversationState.nodeID,
        state.choice.id,
    }, "/")
    context.historySlot = (History.Get(
        state.subjectID,
        state.choice["repeat"],
        context
    ) or { useCount = 0 }).useCount or 0
    state.outcome = Selector.SelectOutcome(
        state.block,
        state.conversationState.nodeID,
        state.choice,
        context
    )
    if not state.outcome then
        return rejected(state, "no_eligible_outcome")
    end
    context.outcomeID = state.outcome.id
    return state
end

Internal.ChoiceHandleContext = ChoiceContext

return ChoiceContext
