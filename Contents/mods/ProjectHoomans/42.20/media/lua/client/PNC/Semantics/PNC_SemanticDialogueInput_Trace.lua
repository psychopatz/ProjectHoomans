-- Semantic dialogue audit and turn-trace payload adapter.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local DialogueInputTrace = PNC.Semantics.DialogueInputTrace or {}
PNC.Semantics.DialogueInputTrace = DialogueInputTrace
local Diagnostics = PNC.Semantics.SemanticDiagnostics

function DialogueInputTrace.Audit(eventName, data, options)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    return Diagnostics.Record(eventName, data, options)
end

function DialogueInputTrace.RecordTurn(view, value, result, event, extra)
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

return DialogueInputTrace
