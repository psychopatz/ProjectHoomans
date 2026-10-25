-- Single semantic-turn submission orchestration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal
local audit = Internal.audit
local traceTurn = Internal.traceTurn
local Suggestions = Internal.Suggestions
local attachInteractionEnvelope = Internal.attachInteractionEnvelope
local SemanticTelemetryPrompt = require
    "PNC/Semantics/PNC_SemanticTelemetryPrompt"

function Internal.SubmitSingle(view, value, part)
    if not view or not view.session then
        return false, "conversation_unavailable"
    end
    if view.session.llmPending
        or view.session.semanticDialoguePending
    then
        return false, "conversation_busy"
    end
    if not (type(part) == "table" and part.compoundPart == true) then
        view.lastSemanticCompound = nil
    end
    local semanticFrame = type(part) == "table"
        and part.semanticFrame or nil
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

    if not semanticFrame
        and not (type(part) == "table" and part.compoundPart == true)
        and type(Internal.ParseTurn) == "function"
    then
        local turn = Internal.ParseTurn(value, nil, view)
        if type(turn) == "table" and turn.compound == true then
            return Internal.SubmitCompound(view, value, turn.parts, part)
        end
    end

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
    local service = Internal.ActorConversationService
        and Internal.ActorConversationService(view) or nil
    local context = Internal.ShallowContext(view)
    local options = {
        timestamp = Internal.Now(),
    }
    local preview
    local cognitionAccepted
    local cognitionRequestID
    local cognitionPending
    local clearSemanticMemoryTarget = false
    local frameIR
    if semanticFrame then
        local frameReason
        local expectedRevision = tonumber(semanticFrame.requestRevision)
        local receiptKey = tostring(view.session.conversationID or "")
            .. ":" .. tostring(expectedRevision)
            .. ":" .. tostring(semanticFrame.candidateID or "")
        view.session.semanticSuggestionReceipts =
            view.session.semanticSuggestionReceipts or {}
        if view.session.semanticSuggestionReceipts[receiptKey] then
            return false, "duplicate_suggestion"
        end
        local currentRevision = tonumber(router.state and router.state.sequence) or 0
        if expectedRevision == nil or expectedRevision ~= currentRevision then
            return false, "stale_suggestion"
        end
        frameIR, frameReason = Suggestions.FrameToIR(semanticFrame, view)
        if not frameIR then return false, frameReason end
        local eligible, eligibilityReason = Suggestions.CheckFrame(
            semanticFrame, context, frameIR
        )
        if eligible ~= true then return false, eligibilityReason end
        preview = {
            schemaVersion = 1,
            kind = "semantic_dialogue_preview",
            accepted = true,
            ir = frameIR,
            decision = router:Decide(frameIR, context, options),
            state = router.state,
            sequence = router.state and router.state.sequence,
        }
    elseif service and type(service.Preview) == "function" then
        preview = service:Preview(value, context, options)
    elseif type(router.Preview) == "function" then
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

    -- Recover only a bounded, question-shaped no-match when the current
    -- conversation supplies a single safe topic. The recovered IR is then
    -- routed through the same production policy and ProcessIR path as an
    -- authored pattern; actions still cannot be created by this spoke.
    if not semanticFrame
        and preview.ir and type(Internal.Recover) == "function"
    then
        local recovered = Internal.Recover(preview.ir, context, options)
        if recovered then
            preview.ir = recovered
            preview.decision = router:Decide(
                recovered,
                context,
                options
            )
            audit("semantic.input.recovered", {
                npcID = view.spec and view.spec.npcID,
                conversationID = view.session.conversationID,
                rawText = value,
                pattern = recovered.provenance
                    and recovered.provenance.pattern,
                topic = recovered.subject,
                confidence = recovered.confidence,
            }, { requestID = preview.sequence })
        end
    end

    attachInteractionEnvelope(
        view,
        preview,
        semanticFrame and "semantic_choice" or "typed_text",
        preview.ir,
        context,
        semanticFrame
    )

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
    local isBackstoryDisclosure = identityRequest
        and identityRequest.kind == "backstory_disclosure"
    if decision.route == "llm_fallback"
        and not isIdentityClaim and not isBackstoryDisclosure
    then
        if Internal.ClearPendingGiftConsent then
            Internal.ClearPendingGiftConsent(view)
        end
        if Internal.SubmitProviderFallback then
            local submitted = Internal.SubmitProviderFallback(
                view, value, part, preview, decision, context, options
            )
            if submitted then
                if service and type(service.ObserveResult) == "function" then
                    service:ObserveResult(preview)
                end
                Internal.RecordConversationTopics(view, preview, value)
                if clearSemanticMemoryTarget and view.session then
                    view.session.semanticMemoryTargetID = nil
                end
                return true
            end
        end
    end

    local result = preview
    if service and type(service.ProcessIR) == "function" then
        result = service:ProcessIR(preview.ir, context, options)
    elseif type(router.Preview) == "function" then
        result = router:ProcessIR(preview.ir, context, options)
    end
    if clearSemanticMemoryTarget and view.session then
        view.session.semanticMemoryTargetID = nil
    end
    view.lastSemanticDialogueResult = result
    if type(result) == "table" and preview.interaction then
        result.interaction = preview.interaction
    end

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

    Internal.RecordAcceptedContextTurn(view, result, options)
    Internal.RecordConversationTopics(view, result, value)

    -- A deterministic parser result that already names an authored
    -- conversation category must use the same category authority lane as a
    -- typed semantic-click frame.  The parser owns recognition only; the
    -- composer/server path still owns block selection, node entry, effects,
    -- and all revalidation.  Do this before the generic semantic response is
    -- queued so the player never receives a redundant "ask the same thing"
    -- suggestion or acknowledgement.
    if not semanticFrame
        and type(Suggestions.BuildConversationCategoryFrame) == "function"
    then
        local categoryFrame = Suggestions.BuildConversationCategoryFrame(
            result and result.ir or nil,
            result and result.sequence
                or router.state and router.state.sequence or 0
        )
        if categoryFrame then
            local categoryVisible = true
            local categoryReason = "category_preflight"
            if type(Suggestions.IsConversationCategoryAvailable)
                == "function"
            then
                categoryVisible, categoryReason =
                    Suggestions.IsConversationCategoryAvailable(
                        categoryFrame, context
                    )
            end
            if categoryVisible then
                local accepted, routeReason =
                    Input.SubmitSemanticFrame(view, categoryFrame)
                if accepted ~= true then
                    traceTurn(view, value, result, "semantic_category_route", {
                        route = "conversation_category",
                        categoryID = categoryFrame.extensions.categoryID,
                        responseSubmitted = false,
                        responseReason = routeReason,
                    })
                    return false, routeReason or categoryReason
                end
                if service and type(service.ObserveResult) == "function" then
                    service:ObserveResult(result)
                end
                if type(Internal.AppendPlayerInput) == "function" then
                    Internal.AppendPlayerInput(
                        view,
                        Suggestions.ResolveFrameText(categoryFrame),
                        result
                    )
                end
                traceTurn(view, value, result, "semantic_category_route", {
                    route = "conversation_category",
                    categoryID = categoryFrame.extensions.categoryID,
                    responseSubmitted = true,
                    responseReason = routeReason,
                })
                return true, routeReason or "accepted"
            end
        end
    end

    -- Claimed identity and targeted preference disclosures are authoritative
    -- server responses. Do not also queue a local reply for those turns.
    local deferIdentityResponse = identityRequest
        and (identityRequest.kind == "identity_claim"
            or identityRequest.kind == "identity_evasion"
            or identityRequest.kind == "gift_preference_disclosure"
            or identityRequest.kind == "backstory_disclosure")
    local compoundPart = type(part) == "table"
        and part.compoundPart == true
    local compoundIndex = compoundPart and tonumber(part.compoundIndex) or nil
    local compoundCount = compoundPart and tonumber(part.compoundCount) or nil
    local deferCompoundResponse = compoundPart
        and compoundIndex ~= nil and compoundCount ~= nil
        and compoundIndex < compoundCount
    local submitted, submitReason = Internal.FinishLocalSubmit(
        view,
        value,
        result,
        { deferResponse = deferIdentityResponse == true
            or deferGossipResponse == true
            or deferCompoundResponse == true,
            skipInputPresentation = compoundPart and compoundIndex ~= 1,
            inputValue = compoundPart and compoundIndex == 1
                and part.compoundRoot or value }
    )
    if submitted == true and service
        and type(service.ObserveResult) == "function"
    then
        service:ObserveResult(result)
    end
    if submitted == true and semanticFrame then
        local revision = tonumber(semanticFrame.requestRevision) or 0
        local receiptKey = tostring(view.session.conversationID or "")
            .. ":" .. tostring(revision)
            .. ":" .. tostring(semanticFrame.candidateID or "")
        view.session.semanticSuggestionReceipts =
            view.session.semanticSuggestionReceipts or {}
        view.session.semanticSuggestionReceipts[receiptKey] = {
            status = "accepted",
            sequence = result and result.sequence,
        }
    end
    if submitted == true then
        Internal.RefreshSuggestions(view, result)
    end
    traceTurn(view, value, result, "semantic_input_local", {
        providerAvailable = context.llmAvailable == true,
        providerUsed = false,
        actionStatus = view.lastSemanticActionResult
            and view.lastSemanticActionResult.status,
        actionAccepted = view.lastSemanticActionResult
            and view.lastSemanticActionResult.accepted,
        actionReason = view.lastSemanticActionResult
            and view.lastSemanticActionResult.reason,
        responseSubmitted = submitted == true,
        responseReason = submitReason,
        compoundRoot = compoundPart and part.compoundRoot or nil,
        compoundIndex = compoundIndex,
        compoundCount = compoundCount,
    })
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

