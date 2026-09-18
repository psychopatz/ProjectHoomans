-- Submission lifecycle for hybrid semantic dialogue input.
--
-- This spoke owns validation, routing, context recording, optional LLM
-- fallback, action dispatch, and response scheduling. Presentation, semantic
-- context construction, and domain adapters remain separate spokes.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal
local Policy = PNC.Semantics.DialoguePolicy
local Diagnostics = PNC.Semantics.SemanticDiagnostics

local function audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    return Diagnostics.Record(eventName, data, options)
end

local function traceTurn(view, value, result, event, extra)
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    local semanticAudit = Diagnostics
        and type(Diagnostics.IsEnabled) == "function"
        and Diagnostics.IsEnabled() == true
    local legacyTrace = trace
        and type(trace.IsEnabled) == "function"
        and trace.IsEnabled() == true
        and type(trace.Record) == "function"
    if not semanticAudit and not legacyTrace then
        return false
    end
    local ir = result and result.ir or {}
    local decision = result and result.decision or {}
    local provenance = ir.provenance or {}
    local group = view and view.groupConversation
    local data = {
        npcID = view and view.spec and view.spec.npcID,
        conversationID = view and view.session
            and view.session.conversationID,
        groupID = group and group.id,
        groupTurnID = group and group.activeTurn
            and group.activeTurn.id or nil,
        groupParticipantCount = group and group.members
            and #group.members or nil,
        rawText = string.sub(tostring(value or ""), 1, 256),
        normalizedText = string.sub(
            tostring(ir.normalizedText or ""), 1, 256
        ),
        route = decision.route,
        branch = decision.branch,
        confidence = ir.confidence,
        intent = ir.intent,
        speechAct = ir.speechAct,
        action = ir.action,
        subject = ir.subject,
        target = ir.target,
        inventoryQuery = ir.inventoryQuery,
        provider = provenance.provider,
        parser = provenance.parser,
        pattern = provenance.pattern,
        diagnostics = ir.diagnostics,
    }
    for key, item in pairs(type(extra) == "table" and extra or {}) do
        data[key] = item
    end
    if semanticAudit then
        return Diagnostics.Record(event or "semantic_input", data, {
            requestID = result and result.sequence,
        })
    end
    return trace.Record({
        source = "ProjectHoomans.Semantics",
        event = event or "semantic_input",
        data = data,
    })
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
        if options.deferResponse ~= true then
            queued = Internal.QueueDeterministicResponse(
                view, value, result, actionResult)
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

function Internal.SubmitSingle(view, value, part)
    if not view or not view.session then
        return false, "conversation_unavailable"
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
        Internal.RequestCognitionForIR(view, preview.ir)
    end
    local identityRequest = Internal.PrepareIdentityRequest
        and Internal.PrepareIdentityRequest(view, preview.ir, context)

    local decision = preview.decision or {}
    if decision.route == "llm_fallback" then
        traceTurn(view, value, preview, "semantic_input_llm_fallback", {
            providerAvailable = context.llmAvailable == true,
        })
        local integration = PNC.PBrainZ
        local llmAvailable = context.llmAvailable == true
        if llmAvailable
            and integration and type(integration.Submit) == "function"
        then
            view.session.semanticDialoguePending = {
                rawText = value,
                normalizedText = preview.ir and preview.ir.normalizedText,
                preview = preview,
                context = context,
                part = part,
            }
            local accepted, reason = integration.Submit(view, value, part)
            if accepted == true then
                view.lastSemanticDialogueResult = preview
                return true
            end
            view.session.semanticDialoguePending = nil
            decision.diagnostics = decision.diagnostics or {}
            decision.diagnostics.llmSubmitReason = reason
        elseif llmAvailable then
            decision.diagnostics = decision.diagnostics or {}
            decision.diagnostics.llmSubmitReason = "llm_submit_unavailable"
        end
        -- Provider absence, stale worker state, and request rejection are all
        -- normal optional-LLM deployment states. Keep the conversation alive
        -- with a deterministic clarification instead of showing a fake wait.
        decision.route = "deterministic"
        decision.branch = "ASK_CLARIFICATION"
        decision.response = Policy.ResponseTemplates.ASK_CLARIFICATION
        context.llmEnabled = false
        context.llmAvailable = false
        options.llmEnabled = false
    end

    local result = preview
    if type(router.Preview) == "function" then
        result = router:ProcessIR(preview.ir, context, options)
    end
    view.lastSemanticDialogueResult = result

    recordAcceptedContextTurn(view, result, options)

    traceTurn(view, value, result, "semantic_input_local", {
        providerAvailable = context.llmAvailable == true,
        providerUsed = false,
    })

    -- A claimed identity is authoritative and asynchronous in multiplayer.
    -- Do not queue the provisional "Nice to meet you. What's your name?"
    -- response here; the server result is the only response for this turn.
    -- Otherwise singleplayer and multiplayer both show two contradictory
    -- replies for one utterance.
    local deferIdentityResponse = identityRequest
        and identityRequest.kind == "identity_claim"
    local submitted, submitReason = finishLocalSubmit(
        view,
        value,
        result,
        { deferResponse = deferIdentityResponse == true }
    )
    if identityRequest and Internal.DispatchIdentityRequest then
        Internal.DispatchIdentityRequest(identityRequest)
    end
    return submitted, submitReason
end

return Internal
