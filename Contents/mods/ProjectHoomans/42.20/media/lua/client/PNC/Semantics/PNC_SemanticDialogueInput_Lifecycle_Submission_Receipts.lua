-- Submission receipts, queueing, and accepted-turn observability.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal
local audit = Internal.audit
local submitLifecycleEnvelope = Internal.submitLifecycleEnvelope

local function applyGeneratedFlowResult(view, result, actionResult)
    local flow = result and result.flow or nil
    local policy = PNC.Semantics and PNC.Semantics.DialoguePolicy or nil
    local kernel = policy and policy.Internal and policy.Internal.FlowKernel
    local state = view and view.session
        and view.session.semanticDialogueState or nil
    if type(flow) ~= "table" or flow.generated ~= true
        or type(actionResult) ~= "table"
        or not kernel or type(kernel.ApplyActionResult) ~= "function"
        or not state or type(Internal.ShallowContext) ~= "function"
    then
        return false
    end
    local updated, reason = kernel.ApplyActionResult(
        flow,
        actionResult,
        state,
        Internal.ShallowContext(view),
        { maxFlowStack = 4 }
    )
    if type(updated) ~= "table" then
        audit("semantic.generated_flow.result_unapplied", {
            flowID = flow.flowId,
            reason = reason,
            status = actionResult.status,
        })
        return false
    end
    result.flow = updated
    if type(result.decision) == "table" then
        result.decision.flow = updated
    end
    return true
end

local function groupMemberShouldHandle(view, result, value)
    local group = view and view.groupConversation
    if not group or type(group.MemberForHost) ~= "function"
        or type(group.ShouldRespond) ~= "function"
    then
        return true
    end
    local member = group:MemberForHost(view)
    return not member or group:ShouldRespond(member, result, value)
end

local function giftConsentResponseView(view, result)
    local consent = result and result.decision
        and result.decision.giftConsent or nil
    local group = view and view.groupConversation or nil
    if type(consent) ~= "table" or not consent.recipientID
        or not group or type(group.ViewFor) ~= "function"
    then
        return view
    end
    return group:ViewFor(consent.recipientID) or view
end

local function finishLocalSubmit(view, value, result, options)
    options = type(options) == "table" and options or {}
    local inputMessage = options.skipInputPresentation == true
        and true or Internal.AppendPlayerInput(
            view, options.inputValue or value, result
        )
    if not inputMessage then return false, "input_presentation_failed" end
    local actionResult
    local queued = false
    view.lastSemanticActionResult = nil
    if groupMemberShouldHandle(view, result, value) then
        actionResult = Internal.DispatchAction(view, result, value)
        view.lastSemanticActionResult = actionResult
        applyGeneratedFlowResult(view, result, actionResult)
        submitLifecycleEnvelope(view, result, actionResult)
        if Internal.ClearPendingGiftConsent then
            Internal.ClearPendingGiftConsent(view)
        end
        if options.deferResponse ~= true then
            queued = Internal.QueueDeterministicResponse(
                giftConsentResponseView(view, result),
                value,
                result,
                actionResult
            )
        end
    else
        audit("semantic.group.member_skipped", {
            groupID = view.groupConversation
                and view.groupConversation.id,
            turnID = view.groupConversation
                and view.groupConversation.activeTurn
                and view.groupConversation.activeTurn.id,
            npcID = view.spec and view.spec.npcID,
            reason = "not_addressed",
        })
    end
    audit("semantic.response.queued", {
        npcID = view.spec and view.spec.npcID,
        conversationID = view.session.conversationID,
        requestID = result.sequence,
        route = result.decision and result.decision.route,
        branch = result.decision and result.decision.branch,
        action = result.ir and result.ir.action,
        actionStatus = actionResult and actionResult.status,
        actionReason = actionResult and actionResult.reason,
        queued = queued == true,
        deferred = options.deferResponse == true,
    }, { requestID = result.sequence })
    return true
end

local function recordAcceptedContextTurn(view, result, options)
    if not Internal.RecordContextTurn or not result
        or result.accepted ~= true or not result.ir
    then
        return false, "context_recording_skipped"
    end
    local recorded, event = Internal.RecordContextTurn(view, result.ir, options)
    audit("semantic.context.recorded", {
        npcID = view.spec and view.spec.npcID,
        conversationID = view.session.conversationID,
        requestID = result.sequence,
        recorded = recorded == true,
        reason = type(event) == "string" and event or nil,
        contextSequence = view.session.semanticDialogueContext
            and view.session.semanticDialogueContext.sequence or nil,
    }, { requestID = result.sequence })
    return recorded, event
end

local function recordConversationTopics(view, result, rawText)
    local session = view and view.session
    local events = PNC.Conversation and PNC.Conversation.Memory
        and PNC.Conversation.Memory.Events or nil
    if not session or not result or result.accepted ~= true
        or type(result.ir) ~= "table"
        or not events or type(events.AccumulateConversationTopics) ~= "function"
    then
        return false
    end
    local ok, recorded = pcall(
        events.AccumulateConversationTopics,
        session,
        result.ir,
        rawText
    )
    return ok and recorded == true
end


Internal.FinishLocalSubmit = finishLocalSubmit
Internal.RecordAcceptedContextTurn = recordAcceptedContextTurn
Internal.RecordConversationTopics = recordConversationTopics
