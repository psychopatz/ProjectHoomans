-- Single semantic-turn routing, result commitment, and response dispatch.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local Input = PNC.ConvoEngine.DialogueInput
local Internal = Input.Internal
local Suggestions = Internal.Suggestions

local function semanticHubPresentationState()
    return Internal.SemanticHubPresentationState
        or PNC.ConvoEngine and PNC.ConvoEngine.SemanticHubPresentationState
end
local audit = Internal.audit
local traceTurn = Internal.traceTurn
local SemanticTelemetryPrompt = require
    "PNC/Semantics/PNC_SemanticTelemetryPrompt"
local FarewellRole = require "PNC/ConvoEngine/Dialogue/FarewellRole"
local Patience = require "PNC/ConvoEngine/PatienceTracker"
if type(Patience) ~= "table" then
    Patience = PNC.ConvoEngine and PNC.ConvoEngine.PatienceTracker or nil
end
local GroupFloor = require "PNC/ConvoEngine/GroupFloor"
if type(GroupFloor) ~= "table" then
    GroupFloor = PNC.ConvoEngine and PNC.ConvoEngine.GroupFloor or nil
end

local function markFarewellEvaluated(view)
    local ls = view and (view.lifecycleState
        or (view.spec and view.spec.context and view.spec.context.conversationLifecycleState))
    if type(ls) == "table" then ls.farewellEvaluated = true end
    local group = view and view.groupConversation
    if type(group) == "table" then
        for _, member in ipairs(group.members or {}) do
            local host = member and member.host
            local hls = host and (host.lifecycleState
                or (host.spec and host.spec.context and host.spec.context.conversationLifecycleState))
            if type(hls) == "table" then hls.farewellEvaluated = true end
        end
    end
end

local function deliverClosingFarewellReply(view, result, context)
    local client = PsychopatzCore and PsychopatzCore.SocialFlavorClient
    if not client or type(client.Enqueue) ~= "function" then return end
    local decision = result and result.decision or {}
    local presCtx = type(Internal.ShallowContext) == "function"
        and Internal.ShallowContext(view) or {}
    presCtx.dialogueIR = result and result.ir
    presCtx.dialogueDecision = decision
    local payloads = Internal.ResponseAdapter and Internal.ResponseAdapter.Payloads
        and Internal.ResponseAdapter.Payloads(decision, presCtx) or {}
    local first = payloads[1] or decision.response or {}
    local text = tostring(first.text or first.fallback or "")
    if text == "" then return end
    local npcID = tostring(view and view.spec and view.spec.npcID or context and context.npcID or "")
    if npcID == "" then return end
    local role = FarewellRole.ResolveFromContext(context, npcID)
    client.Enqueue({
        eventID = "semantic-farewell:" .. npcID .. ":" .. tostring(result and result.sequence or 0),
        flavorID = first.renderTemplateID or first.templateID or "semantic.social.farewell.depart",
        text = text,
        semanticOwned = true,
        family = "conversation_farewell",
        priority = 72,
        weight = 1,
        speakerID = npcID,
        speakerName = context and context.npcFullName or npcID,
        speakerKind = "npc",
        playerUUID = context and context.characterUUID,
        llmEligible = false,
        memoryEligible = false,
        ttlMs = 9000,
        cooldowns = { ambientMs = 0, familyMs = 0, speakerMs = 0 },
        presentationState = { nameplate = true, conversationUI = false, interrupt = false, tts = true },
        source = {
            kind = "semantic_speech",
            eventType = "conversation_farewell",
            socialRole = role,
            semanticAct = "FAREWELL",
            topic = "farewell",
        },
    })
end

function Internal.CommitSingleSubmission(view, prepared, interpretation)
    local value = prepared.value
    local part = prepared.part
    local semanticFrame = prepared.semanticFrame
    local transientSemanticSurface =
        prepared.semanticTransientSurface == true
    local router = interpretation.router
    local service = interpretation.service
    local context = interpretation.context
    local options = interpretation.options
    local preview = interpretation.preview
    local cognitionRequestID = interpretation.cognitionRequestID
    local cognitionPending = interpretation.cognitionPending
    local clearSemanticMemoryTarget = interpretation.clearSemanticMemoryTarget
    local identityRequest = interpretation.identityRequest

    local decision = preview.decision or {}
    local isIdentityClaim = identityRequest
        and identityRequest.kind == "identity_claim"
    local isBackstoryDisclosure = identityRequest
        and identityRequest.kind == "backstory_disclosure"
    local isFactionDisclosure = identityRequest
        and (identityRequest.kind == "faction_disclosure"
            or identityRequest.kind == "identity_facet_disclosure")
    if decision.route == "llm_fallback"
        and not isIdentityClaim and not isBackstoryDisclosure
        and not isFactionDisclosure
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

    local patMod = type(Patience) == "table" and Patience or (PNC.ConvoEngine and PNC.ConvoEngine.PatienceTracker)
    if type(patMod) == "table" and type(patMod.EnrichContext) == "function" then
        patMod.EnrichContext(preview and preview.ir or nil, context)
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
    local deferFactResponse = cognitionPending == true
        and cognitionRequestID ~= nil
        and preview.ir
        and Internal.IsDeferredFactSubject
        and Internal.IsDeferredFactSubject(preview.ir.subject)
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
    if deferFactResponse then
        view.session.semanticFactRequestID = tostring(cognitionRequestID)
        view.session.semanticFactRequestValue = value
        view.session.semanticFactRequestResult = result
        view.session.semanticDialoguePending = {
            kind = "semantic_fact",
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
    local gfMod = type(GroupFloor) == "table" and GroupFloor or (PNC.ConvoEngine and PNC.ConvoEngine.GroupFloor)
    if view and view.groupConversation and type(gfMod) == "table" and type(gfMod.RecordTurn) == "function" then
        local ir = result and result.ir or {}
        gfMod.RecordTurn(view.groupConversation.id or context.conversationID or "group", {
            speakerID = context.npcID,
            speakerName = context.npcFullName,
            speakerIsPlayer = false,
            addresseeID = context.characterUUID or "player",
            intent = ir.intent,
            action = ir.action,
            subject = ir.subject,
            moodPrimary = context.moodPrimary,
            npcAnnoyed = context.npcAnnoyed == true,
            npcFedUp = context.npcFedUp == true,
            speakerInjured = context.speakerInjured == true,
        })
    end

    -- A deterministic parser result that already names an authored
    -- conversation category must use the same category authority lane as a
    -- typed semantic-click frame.  The parser owns recognition only; the
    -- composer/server path still owns block selection, node entry, effects,
    -- and all revalidation.  Do this before the generic semantic response is
    -- queued so the player never receives a redundant acknowledgement.
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
            or identityRequest.kind == "backstory_disclosure"
            or identityRequest.kind == "faction_disclosure"
            or identityRequest.kind == "identity_facet_disclosure")
    local compoundPart = type(part) == "table"
        and part.compoundPart == true
    local compoundIndex = compoundPart and tonumber(part.compoundIndex) or nil
    local compoundCount = compoundPart and tonumber(part.compoundCount) or nil
    local deferCompoundResponse = compoundPart
        and compoundIndex ~= nil and compoundCount ~= nil
        and compoundIndex < compoundCount
    local closeOnFarewell = finalDecision and (
        finalDecision.branch == "FAREWELL_ACKNOWLEDGED"
        or finalDecision.closeConversation == true
    )
    local submitted, submitReason = Internal.FinishLocalSubmit(
        view,
        value,
        result,
        { deferResponse = transientSemanticSurface
            or deferIdentityResponse == true
            or deferGossipResponse == true
            or deferFactResponse == true
            or deferCompoundResponse == true
            or closeOnFarewell == true,
            skipInputPresentation = transientSemanticSurface
                or (type(view) == "table" and view._suppressNextPlayerInputEcho == true)
                or (type(part) == "table" and part.skipInputPresentation == true)
                or (compoundPart and compoundIndex ~= 1),
            inputValue = compoundPart and compoundIndex == 1
                and part.compoundRoot or value }
    )
    if submitted == true and service
        and type(service.ObserveResult) == "function"
    then
        service:ObserveResult(result)
    end
    if submitted == true and semanticFrame then
        local presentationState = semanticHubPresentationState()
        if presentationState
            and type(presentationState.Mark) == "function"
        then
            presentationState.Mark(view, context, semanticFrame)
        end
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
    if submitted == true and closeOnFarewell then
        markFarewellEvaluated(view)
        deliverClosingFarewellReply(view, result, context)
        if view.headless ~= true and type(view.close) == "function" then
            view:close("semantic_farewell")
        end
    elseif submitted == true and not transientSemanticSurface then
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

return Input
