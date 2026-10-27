-- Semantic dialogue audit and turn-trace payload adapter.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local DialogueInputTrace = PNC.Semantics.DialogueInputTrace or {}
PNC.Semantics.DialogueInputTrace = DialogueInputTrace
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local Handshake = PNC.Semantics.SemanticCapabilityHandshake

local function ensureHandshake()
    if Diagnostics
        and type(Diagnostics.IsEnabled) == "function"
        and Diagnostics.IsEnabled() == true
        and Handshake
        and type(Handshake.Report) == "function"
    then
        Handshake.Report()
    end
end

local function hasMatchedPattern(ir)
    local provenance = ir and ir.provenance or nil
    local diagnostics = ir and ir.diagnostics or nil
    return type(provenance) == "table"
        and tostring(provenance.pattern or "") ~= ""
        and not (type(diagnostics) == "table" and diagnostics.noMatch == true)
end

local function primaryClassification(ir, decision, extra)
    local actionResult = type(extra) == "table" and {
        status = extra.actionStatus,
        accepted = extra.actionAccepted,
        reason = extra.actionReason,
    } or nil
    local diagnostics = ir and ir.diagnostics or nil
    local extensions = ir and ir.extensions or nil
    local intent = tostring(ir and ir.intent or "")
    local speechAct = tostring(ir and ir.speechAct or "")
    if ir and ir.action and type(actionResult) == "table"
        and actionResult.accepted == true
    then
        return "authorized_gameplay_action"
    end
    if not hasMatchedPattern(ir) then
        return "unrecognized_language"
    end
    if intent == "QUESTION" or speechAct == "QUESTION" then
        if type(diagnostics) == "table"
            and diagnostics.factStatus == "unknown"
            and not (type(extensions) == "table"
                and extensions.dialogueFollowUp
                    == "CONVERSATION_CONTINUATION")
        then
            return "recognized_question_unknown_fact"
        end
        return "recognized_question"
    end
    if intent == "COMPLIMENT" or intent == "GOSSIP"
        or intent == "INSULT" or intent == "THREATEN"
        or intent == "HOSTILE_REMARK" or intent == "SELF_REFLECTION"
        or speechAct == "COMPLIMENT" or speechAct == "GOSSIP"
    then
        return "recognized_social_interaction"
    end
    if decision and decision.branch == "ASK_CLARIFICATION" then
        return "recognized_input_needing_clarification"
    end
    return "recognized_semantic_input"
end

local function responsePlanSummary(response)
    local plan = response and response.plan or nil
    if type(plan) ~= "table" then return nil end
    return {
        dialogueAct = plan.dialogueAct,
        sourcePoolID = plan.sourcePoolID,
        topic = plan.topic,
        groundedFactRefs = plan.groundedFactRefs,
        uncertainty = plan.uncertainty,
        tone = plan.tone,
        personalityStyle = plan.personalityStyle,
    }
end

function DialogueInputTrace.Audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    ensureHandshake()
    return Diagnostics.Record(eventName, data, options)
end

function DialogueInputTrace.RecordTurn(view, value, result, event, extra)
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    local semanticAudit = Diagnostics
        and type(Diagnostics.IsEnabled) == "function"
        and Diagnostics.IsEnabled() == true
    local coreTrace = trace
        and type(trace.IsEnabled) == "function"
        and trace.IsEnabled() == true
        and type(trace.Record) == "function"
    if not semanticAudit and not coreTrace then
        return false
    end
    if semanticAudit then ensureHandshake() end
    local ir = result and result.ir or {}
    local decision = result and result.decision or {}
    local provenance = ir.provenance or {}
    local response = decision.response
    local responsePlan = responsePlanSummary(response)
    local actionResult = extra and extra.actionResult or nil
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
        classification = primaryClassification(ir, decision, extra),
        responseClassification = responsePlan
            and "grounded_npc_response" or nil,
        response = response and {
            templateID = response.templateID,
            sourcePoolID = response.sourcePoolID,
            selectionSource = response.selectionSource,
            selectionID = response.selectionID,
            uncertainty = response.uncertainty,
            groundedFactRefs = response.groundedFactRefs,
        } or nil,
        responsePlan = responsePlan,
        fact = {
            status = ir.diagnostics and ir.diagnostics.factStatus,
            provider = ir.diagnostics and ir.diagnostics.factProvider,
            reason = ir.diagnostics and ir.diagnostics.factReason,
        },
        sideEffects = {
            action = ir.action,
            actionStatus = actionResult and actionResult.status,
            actionAccepted = actionResult and actionResult.accepted,
            actionReason = actionResult and actionResult.reason,
        },
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

return DialogueInputTrace
