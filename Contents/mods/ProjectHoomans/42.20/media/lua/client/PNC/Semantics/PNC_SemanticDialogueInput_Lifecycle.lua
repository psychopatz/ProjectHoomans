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
local Suggestions = PNC.Semantics.DialogueSuggestions
if type(Suggestions) ~= "table" then
    require "PNC/Semantics/PNC_SemanticDialogueSuggestions"
    Suggestions = PNC.Semantics.DialogueSuggestions
end
Suggestions = type(Suggestions) == "table" and Suggestions or {}

local function suggestionText(row)
    local display = row and row.display or {}
    return tostring(
        display.label
            or display.labelFallback
            or display.utterance
            or display.utteranceFallback
            or row and (row.id or row.action)
            or ""
    )
end

local function suggestionTooltip(row)
    local status = row and row.status or row and row.eligibility
        and row.eligibility.status or ""
    local text = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text or nil
    if status == "requires_destination"
        or status == "selected_requires_destination"
    then
        return text and type(text.Resolve) == "function"
            and text.Resolve({
                key = "UI_PNC_Conversation_Suggestion_NeedsDestination_Tooltip",
                fallback = "Choose a destination first.",
            }) or "Choose a destination first."
    end
    if status ~= "" and string.sub(status, 1, 12) == "unavailable_" then
        return text and type(text.Resolve) == "function"
            and text.Resolve({
                key = "UI_PNC_Conversation_Suggestion_Unavailable_Tooltip",
                fallback = "Unavailable in the current situation.",
            }) or "Unavailable in the current situation."
    end
    return nil
end

-- Build rows for Core's native choice list. This is a data adapter only: Core
-- still owns layout, scrolling, hover, click gating, and session ordering; the
-- canonical semantic input path owns the click frame.
local function buildCoreChoices(view, projection)
    projection = type(projection) == "table" and projection or {}
    local selectedGroup
    local requestedGroup = projection.currentGroupID
    for _, group in ipairs(projection.groups or {}) do
        if group.id == requestedGroup then
            selectedGroup = group
            break
        end
    end
    if not selectedGroup and #(projection.groups or {}) > 0 then
        selectedGroup = projection.groups[1]
    end

    local rows = {}
    local function append(row, enabled)
        local frame = row and row.frame or nil
        if type(frame) ~= "table" then return end
        rows[#rows + 1] = {
            id = row.id or row.action or ("semantic:" .. tostring(#rows + 1)),
            text = suggestionText(row),
            enabled = enabled == true,
            tooltip = suggestionTooltip(row),
            -- The Core row is a typed semantic click adapter. Its action
            -- owns the one canonical submission path, so Core must not also
            -- append the display text as an authored player turn.
            log = false,
            source = {
                semanticFrame = frame,
                source = row.source,
                groupID = selectedGroup and selectedGroup.id
                    or row.groupID,
            },
            action = function()
                local input = PNC.Semantics
                    and PNC.Semantics.DialogueInput or nil
                if not input or type(input.SubmitSemanticFrame)
                    ~= "function"
                then
                    view.lastSemanticSuggestionReason =
                        "semantic_input_unavailable"
                    return false
                end
                local accepted, reason = input.SubmitSemanticFrame(
                    view, frame
                )
                view.lastSemanticSuggestionReason = reason
                return accepted
            end,
        }
    end

    -- Core's native list is scrollable, so the projection can expose every
    -- currently safe topic without a hidden five-row global cap. Navigation
    -- rows use the same typed click contract and only change the selected
    -- projection group; they never parse or execute gameplay.
    for _, group in ipairs(projection.groups or {}) do
        if not selectedGroup or group.id ~= selectedGroup.id then
            local frame = Suggestions.BuildGroupFrame
                and Suggestions.BuildGroupFrame(group, projection.revision)
                or nil
            if frame then
                append({
                    id = frame.candidateID,
                    frame = frame,
                    display = {
                        label = group.label,
                        labelFallback = group.label,
                    },
                    source = {
                        kind = "semantic_group_navigation",
                        revision = projection.revision,
                        groupID = group.id,
                    },
                }, true)
            end
        end
    end

    local candidates = selectedGroup and selectedGroup.candidates
        or projection.candidates or {}
    for _, candidate in ipairs(candidates) do
        append(candidate, candidate.enabled ~= false)
    end
    local capabilities = selectedGroup and selectedGroup.capabilities
        or projection.permittedCapabilities or {}
    for _, capability in ipairs(capabilities) do
        append(capability,
            capability.status == "eligible"
                or capability.status == "selected_for_preflight")
    end
    if view then view.semanticSuggestionRows = rows end
    return rows
end

-- This callback is installed in the Core conversation definition. Core calls
-- it after every authored choice normalization, including pending-response
-- completion and in-place spec refresh. Returning nil preserves Core's
-- normalized authored choices as the safe fallback.
local function presentSemanticChoices(view, authoredChoices)
    local projection = view and view.semanticSuggestions or nil
    if type(projection) ~= "table" then return nil end
    local rows = buildCoreChoices(view, projection)
    if #rows > 0 then return rows end
    return nil
end

local function applyCoreChoices(view, projection)
    local session = view and view.session or nil
    if not session or type(session.setPresentedChoices) ~= "function" then
        return false, "core_choices_unavailable"
    end
    local rows = buildCoreChoices(view, projection)
    if #rows < 1 then
        -- A projection can legitimately be empty while a dependency or
        -- current topic is unavailable. Restore the authored Core choices
        -- when the session is idle; never expose stale choices during a
        -- queued response.
        if session.busy == true then
            -- Session:finishPending will call Core's normal setChoices after
            -- the queued reply; its presentation callback then supplies the
            -- projection or the authored fallback.
            view.semanticPresentationPending = projection
            return false, "semantic_choices_deferred"
        end
        local node = session.currentNode or {}
        if type(session.setChoices) == "function" then
            session:setChoices(node.choices or {})
        end
        return false, "semantic_choices_empty"
    end
    view.semanticPresentationPending = nil
    local applied = session:setPresentedChoices(rows, {
        source = "semantic_suggestions",
        revision = projection and projection.revision,
        presentedCount = #rows,
    })
    return applied == true, rows
end

Internal.PresentSemanticChoices = presentSemanticChoices
Internal.ApplySemanticChoices = applyCoreChoices

function Internal.RefreshSuggestions(view, result)
    if not view or type(result) ~= "table"
        or type(Suggestions.Build) ~= "function"
    then
        return nil
    end
    local projection = Suggestions.Build(
        result,
        type(Internal.ShallowContext) == "function"
            and Internal.ShallowContext(view) or {},
        nil
    )
    view.semanticSuggestions = projection
    view.semanticSuggestionRevision = projection
        and projection.revision or nil
    applyCoreChoices(view, projection)
    return projection
end

-- Rebuild the semantic surface from the current production root node without
-- inventing a turn or advancing router state. This is used when a Core choice
-- transition returns to the menu and on the initial root presentation.
function Internal.RefreshRootSuggestions(view)
    if not view or type(Suggestions.Build) ~= "function"
        or type(Internal.ShallowContext) ~= "function"
    then
        return nil
    end
    if view.closed == true or view.closing == true
        or view.lifecycleFinished == true
        or view.session and view.session.closed == true
    then
        view.semanticSuggestions = nil
        return nil
    end
    local context = Internal.ShallowContext(view)
    if type(context.conversationRoot) ~= "table" then return nil end
    -- Do not create the semantic router merely to paint the initial menu.
    -- RouterFor owns turn state initialization, and doing that here changes
    -- the authoritative contextBefore snapshot before the first input. Reuse
    -- an existing router when a prior turn already created one; otherwise the
    -- initial root revision is the canonical zero revision.
    local router = view.session and view.session.semanticDialogueRouter
    local revision = router and router.state
        and tonumber(router.state.sequence) or 0
    local projection = Suggestions.Build({
        accepted = false,
        sequence = revision,
        state = { sequence = revision },
        ir = {},
        decision = {},
    }, context, nil)
    view.semanticSuggestions = projection
    view.semanticSuggestionRevision = projection
        and projection.revision or nil
    applyCoreChoices(view, projection)
    return projection
end

function Internal.SelectSemanticGroup(view, frame)
    if not view or not view.session
        or type(Suggestions.IsGroupFrame) ~= "function"
        or not Suggestions.IsGroupFrame(frame)
    then
        return false, "semantic_group_frame_invalid"
    end
    local projection = view.semanticSuggestions
    if type(projection) ~= "table" then
        return false, "semantic_suggestions_unavailable"
    end
    if tonumber(frame.requestRevision) ~= tonumber(projection.revision) then
        return false, "stale_suggestion"
    end
    local selected
    for _, group in ipairs(projection.groups or {}) do
        if tostring(group.id or "") == tostring(frame.groupID) then
            selected = group
            break
        end
    end
    if not selected then return false, "semantic_group_unknown" end
    projection.currentGroupID = selected.id
    local applied, reason = applyCoreChoices(view, projection)
    if not applied then return false, reason end
    return true, "accepted"
end

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

function Internal.SubmitCompound(view, value, parts, sourcePart)
    if type(parts) ~= "table" or #parts < 2 then
        return false, "compound_turn_invalid"
    end
    local index
    local part
    local submitted = true
    local reason
    local receipts = {}
    view.lastSemanticCompound = {
        schemaVersion = 1,
        rawText = value,
        parts = receipts,
    }
    for index = 1, #parts do
        part = parts[index]
        submitted, reason = Internal.SubmitSingle(view, part.text, {
            compoundPart = true,
            compoundRoot = value,
            compoundIndex = index,
            compoundCount = #parts,
            sourcePart = sourcePart,
        })
        receipts[index] = {
            index = index,
            text = part.text,
            accepted = submitted == true,
            reason = reason,
            pattern = view.lastSemanticDialogueResult
                and view.lastSemanticDialogueResult.ir
                and view.lastSemanticDialogueResult.ir.provenance
                and view.lastSemanticDialogueResult.ir.provenance.pattern,
            intent = view.lastSemanticDialogueResult
                and view.lastSemanticDialogueResult.ir
                and view.lastSemanticDialogueResult.ir.intent,
            subject = view.lastSemanticDialogueResult
                and view.lastSemanticDialogueResult.ir
                and view.lastSemanticDialogueResult.ir.subject,
            flow = view.lastSemanticDialogueResult
                and view.lastSemanticDialogueResult.decision
                and view.lastSemanticDialogueResult.decision.flow
                and view.lastSemanticDialogueResult.decision.flow.transition,
        }
        if not submitted then return false, reason end
    end
    return true
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
                recordConversationTopics(view, preview, value)
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
            or identityRequest.kind == "gift_preference_disclosure"
            or identityRequest.kind == "backstory_disclosure")
    local compoundPart = type(part) == "table"
        and part.compoundPart == true
    local compoundIndex = compoundPart and tonumber(part.compoundIndex) or nil
    local compoundCount = compoundPart and tonumber(part.compoundCount) or nil
    local deferCompoundResponse = compoundPart
        and compoundIndex ~= nil and compoundCount ~= nil
        and compoundIndex < compoundCount
    local submitted, submitReason = finishLocalSubmit(
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
    local groundedGossip = context and context.npcGossip or nil
    if not groundedGossip
        or groundedGossip.source ~= "world_knowledge"
    then
        local clientState = PNC.Network and PNC.Network.ClientState or nil
        local clientGossip = clientState
            and clientState.semanticWorldKnowledgeGossip or nil
        local npcID = view.spec and tostring(view.spec.npcID or "") or ""
        groundedGossip = clientGossip and clientGossip[npcID] or nil
    end
    if groundedGossip and groundedGossip.source == "world_knowledge"
        and type(groundedGossip.factRefs) == "table"
        and #groundedGossip.factRefs > 0
    then
        local response = result.decision.response
        if type(response) == "table" then
            response.groundedFactRefs = {}
            for index = 1, math.min(#groundedGossip.factRefs, 4) do
                response.groundedFactRefs[#response.groundedFactRefs + 1] =
                    groundedGossip.factRefs[index]
            end
            response.selectionSource = "world_knowledge"
            if type(response.plan) == "table" then
                response.plan.groundedFactRefs = response.groundedFactRefs
                response.plan.sourcePoolID = "world_knowledge"
            end
        end
    end
    localResponse = PNC.Semantics and PNC.Semantics.LocalResponse or nil
    if localResponse and type(localResponse.Resolve) == "function" then
        decision.response = localResponse.Resolve(
            result.ir,
            session.semanticDialogueState,
            context,
            decision.branch
        ) or decision.response
    end
    if groundedGossip and groundedGossip.source == "world_knowledge"
        and type(groundedGossip.factRefs) == "table"
        and #groundedGossip.factRefs > 0
        and type(decision.response) == "table"
    then
        decision.response.groundedFactRefs = {}
        for index = 1, math.min(#groundedGossip.factRefs, 4) do
            decision.response.groundedFactRefs[#decision.response.groundedFactRefs + 1] =
                groundedGossip.factRefs[index]
        end
        decision.response.selectionSource = "world_knowledge"
        if type(decision.response.plan) == "table" then
            decision.response.plan.groundedFactRefs =
                decision.response.groundedFactRefs
            decision.response.plan.sourcePoolID = "world_knowledge"
        end
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
