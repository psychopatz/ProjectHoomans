-- Submission lifecycle for hybrid semantic dialogue input.
--
-- This spoke owns validation, routing, context recording, optional LLM
-- fallback, action dispatch, and response scheduling. Presentation, semantic
-- context construction, and domain adapters remain separate spokes.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

require "PNC/Conversation/Memory/PNC_ConversationMemory"
require "PNC/Conversation/Definitions/Memory/ConversationTopics/00_PNC_ConversationMemoryTopics"

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal
local DialogueInputTrace = PNC.Semantics.DialogueInputTrace
local audit = DialogueInputTrace.Audit
local traceTurn = DialogueInputTrace.RecordTurn

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
    local inputMessage = Internal.AppendPlayerInput(view, value, result)
    if not inputMessage then return false, "input_presentation_failed" end
    local actionResult
    local queued = false
    view.lastSemanticActionResult = nil
    if groupMemberShouldHandle(view, result, value) then
        actionResult = Internal.DispatchAction(view, result, value)
        view.lastSemanticActionResult = actionResult
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

local SemanticTelemetryPrompt = require
    "PNC/Semantics/PNC_SemanticTelemetryPrompt"

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

function Internal.SubmitSingle(view, value, part)
    if not view or not view.session then
        return false, "conversation_unavailable"
    end
    if view.session.llmPending
        or view.session.semanticDialoguePending
    then
        return false, "conversation_busy"
    end
    -- Keep the submitting host available to asynchronous local projections.
    -- Full-screen conversations are discoverable through Core's singleton,
    -- while compact/headless conversations are deliberately not global.  The
    -- reference is runtime-only and is never serialized or sent over the
    -- network.
    Input.ActiveView = view
    view.lastSemanticActionResult = nil
    if not Internal.Interactive(view) then return false, "conversation_busy" end
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return false, "empty_message" end
    value = string.sub(value, 1, Input.MAX_INPUT_LENGTH)

    audit("semantic.input.received", {
        npcID = view.spec and view.spec.npcID,
        conversationID = view.session.conversationID,
        rawText = value,
    })

    local router, routerReason = Internal.RouterFor(view)
    if not router then
        audit("semantic.input.rejected", {
            npcID = view.spec and view.spec.npcID,
            conversationID = view.session.conversationID,
            rawText = value,
            reason = routerReason,
        })
        return false, routerReason
    end
    local context = Internal.ShallowContext(view)
    local options = {
        timestamp = Internal.Now(),
    }
    local preview
    local cognitionAccepted
    local cognitionRequestID
    local cognitionPending
    local clearSemanticMemoryTarget = false
    if type(router.Preview) == "function" then
        preview = router:Preview(value, context, options)
    else
        preview = router:Process(value, context, options)
    end
    if preview.accepted ~= true then
        audit("semantic.input.rejected", {
            npcID = view.spec and view.spec.npcID,
            conversationID = view.session.conversationID,
            rawText = value,
            reason = preview.reason,
        })
        return false, preview.reason or "semantic_input_rejected"
    end

    if Internal.RequestCognitionForIR then
        cognitionAccepted, _, cognitionRequestID, cognitionPending =
            Internal.RequestCognitionForIR(view, preview.ir)
        if preview.ir and preview.ir.intent == "GOSSIP"
            and cognitionAccepted == true
            and cognitionPending ~= true
        then
            -- Single-player/server-hosted cognition can finish synchronously.
            -- Rebuild the snapshot after the server fills its memory cache so
            -- this same turn can use the returned gossip.
            context = Internal.ShallowContext(view)
            clearSemanticMemoryTarget = true
        end
    end
    local identityRequest = Internal.PrepareIdentityRequest
        and Internal.PrepareIdentityRequest(view, preview.ir, context)

    local decision = preview.decision or {}
    local isIdentityClaim = identityRequest
        and identityRequest.kind == "identity_claim"
    if decision.route == "llm_fallback" and not isIdentityClaim then
        if Internal.ClearPendingGiftConsent then
            Internal.ClearPendingGiftConsent(view)
        end
        if Internal.SubmitProviderFallback then
            local submitted = Internal.SubmitProviderFallback(
                view, value, part, preview, decision, context, options
            )
            if submitted then
                recordConversationTopics(view, preview, value)
                if clearSemanticMemoryTarget and view.session then
                    view.session.semanticMemoryTargetID = nil
                end
                return true
            end
        end
    end

    local result = preview
    if type(router.Preview) == "function" then
        result = router:ProcessIR(preview.ir, context, options)
    end
    if clearSemanticMemoryTarget and view.session then
        view.session.semanticMemoryTargetID = nil
    end
    view.lastSemanticDialogueResult = result

    local finalDecision = result and result.decision or {}
    local deferGossipResponse = cognitionPending == true
        and cognitionRequestID ~= nil
        and preview.ir and preview.ir.intent == "GOSSIP"
        and finalDecision.branch == "GOSSIP_RECEIVED"
        and not view.groupConversation
    if deferGossipResponse then
        view.session.semanticGossipRequestID = tostring(cognitionRequestID)
        view.session.semanticGossipRequestValue = value
        view.session.semanticGossipRequestResult = result
        view.session.semanticDialoguePending = {
            kind = "semantic_gossip",
            requestID = tostring(cognitionRequestID),
        }
    end
    if finalDecision.branch == "ASK_CLARIFICATION"
        and type(SemanticTelemetryPrompt) == "table"
        and type(SemanticTelemetryPrompt.Offer) == "function"
    then
        SemanticTelemetryPrompt.Offer(view, value, result, "local")
    end

    recordAcceptedContextTurn(view, result, options)
    recordConversationTopics(view, result, value)

    traceTurn(view, value, result, "semantic_input_local", {
        providerAvailable = context.llmAvailable == true,
        providerUsed = false,
    })

    -- Claimed identity and targeted preference disclosures are authoritative
    -- server responses. Do not also queue a local reply for those turns.
    local deferIdentityResponse = identityRequest
        and (identityRequest.kind == "identity_claim"
            or identityRequest.kind == "gift_preference_disclosure")
    local submitted, submitReason = finishLocalSubmit(
        view,
        value,
        result,
        { deferResponse = deferIdentityResponse == true
            or deferGossipResponse == true }
    )
    if identityRequest then
        local dispatched = false
        local dispatchReason
        local requestID
        if Internal.DispatchIdentityRequest then
            dispatched, dispatchReason, requestID =
                Internal.DispatchIdentityRequest(identityRequest)
        end
        if identityRequest.kind == "identity_claim"
            or identityRequest.kind == "identity_evasion"
        then
            audit("semantic.identity.request_dispatched", {
                requestID = requestID or result.sequence,
                inputSequence = result.sequence,
                npcID = tostring(identityRequest.npcID or ""),
                conversationID = view.session
                    and view.session.conversationID or nil,
                kind = tostring(identityRequest.kind or ""),
                accepted = dispatched == true,
                reason = tostring(dispatchReason or ""),
                claimedNamePresent = identityRequest.claimedName ~= nil
                    and tostring(identityRequest.claimedName) ~= "",
                conversationTokenPresent = identityRequest.conversationToken
                    ~= nil
                    and tostring(identityRequest.conversationToken) ~= "",
            }, { requestID = requestID or result.sequence })
        end
        if identityRequest.kind == "identity_claim" and dispatched ~= true
            and Internal.IdentityExchangeUnavailableResponse
            and Internal.QueueDeterministicResponse
        then
            Internal.QueueDeterministicResponse(
                view,
                value,
                result,
                nil,
                {
                    response = Internal.IdentityExchangeUnavailableResponse(),
                }
            )
        end
    end
    return submitted, submitReason
end

function Input.CompleteGossipRequest(request)
    local view = request and request.view or nil
    local session = request and request.session or nil
    local requestID = tostring(request and request.requestID or "")
    local result
    local decision
    local localResponse
    local context
    local value
    if not view or not session or requestID == ""
        or view.session ~= session or session.closed == true
        or view.closed == true or view.closing == true
        or tostring(session.semanticGossipRequestID or "") ~= requestID
        or type(session.semanticDialoguePending) ~= "table"
        or tostring(session.semanticDialoguePending.requestID or "")
            ~= requestID
    then
        return false, "stale_gossip_request"
    end
    result = session.semanticGossipRequestResult
    value = session.semanticGossipRequestValue
    decision = result and result.decision or nil
    if not result or not result.ir or not decision then
        return false, "gossip_response_unavailable"
    end
    context = Internal.ShallowContext(view)
    localResponse = PNC.Semantics and PNC.Semantics.LocalResponse or nil
    if localResponse and type(localResponse.Resolve) == "function" then
        decision.response = localResponse.Resolve(
            result.ir,
            session.semanticDialogueState,
            context,
            decision.branch
        ) or decision.response
    end
    session.semanticMemoryTargetID = nil
    session.semanticGossipRequestID = nil
    session.semanticGossipRequestResult = nil
    session.semanticGossipRequestValue = nil
    session.semanticDialoguePending = nil
    if type(Internal.QueueDeterministicResponse) ~= "function" then
        return false, "response_queue_unavailable"
    end
    return Internal.QueueDeterministicResponse(view, value, result, nil)
end

return Internal
