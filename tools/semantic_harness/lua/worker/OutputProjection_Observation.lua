-- Observation envelope projection.

local Observation = {}
local Bounds = require "worker/OutputProjection_ObservationBounds"
local Response = require "worker/OutputProjection_ObservationResponse"
local Suggestions = require "worker/OutputProjection_ObservationSuggestions"

function Observation.build(context, record, semanticContext)
    local Values = context.Values
    record = type(record) == "table" and record or {}
    local result = type(record.result) == "table" and record.result or {}
    local ir = type(result.ir) == "table" and result.ir or {}
    local decision = type(result.decision) == "table"
        and result.decision or {}
    local flow = type(decision.flow) == "table" and decision.flow or {}
    local response = type(decision.response) == "table"
        and decision.response or {}
    local selectedCandidate = type((result.candidates or {}).selected) == "table"
        and result.candidates.selected or {}
    local responseObservation = Response.build(context, record, response)
    responseObservation.flowResponsePoolID = flow.responsePool
    return {
        schemaVersion = 1,
        input = tostring(record.input or ""),
        accepted = record.accepted == true,
        reason = record.reason,
        ir = {
            intent = ir.intent,
            speechAct = ir.speechAct,
            action = ir.action,
            subject = ir.subject,
            confidence = ir.confidence,
            normalizedText = ir.normalizedText,
            pattern = ir.provenance and ir.provenance.pattern,
        },
        capabilityBinding = Bounds.capabilityBinding(context, ir.action),
        actionResult = Values.copy(result.actionResult),
        candidates = Bounds.candidates(context, result),
        response = responseObservation,
        suggestions = Suggestions.build(context, record, result, semanticContext),
        conversationBlock = Values.copy(record.conversationBlock),
        flow = {
            flowId = flow.flowId,
            generated = flow.generated == true,
            workflowKind = flow.workflowKind,
            capabilityID = flow.capabilityID,
            binding = Values.copy(flow.binding),
            matched = flow.matched == true,
            noFlow = flow.matched ~= true,
            fromNodeId = flow.fromNodeId,
            toNodeId = flow.toNodeId or flow.nodeId,
            transition = flow.transition,
            status = flow.status,
            committed = flow.committed == true,
            gateStatus = flow.gate and flow.gate.status,
            gateReason = flow.gate and flow.gate.reason,
            gate = Values.copy(flow.gate),
            responsePoolID = flow.responsePool,
            resultOutcome = flow.resultOutcome,
            resultStatus = flow.resultStatus,
            resultReason = flow.resultReason,
            resultNodeId = flow.resultNodeId,
            dispatchCount = flow.dispatchCount,
            resumedFlowId = flow.resumedFlowId,
            completedFlowId = flow.completedFlowId,
            activeBefore = Bounds.flowSessions(record.contextBefore),
            activeAfter = Bounds.flowSessions(record.contextAfter),
        },
        translation = Bounds.translation(context, record.translation),
        sideEffects = Bounds.sideEffects(
            context, record.transport, record.toolCalls
        ),
        context = {
            currentTopic = record.contextAfter
                and record.contextAfter.dialogue
                and record.contextAfter.dialogue.currentTopic,
            pendingIdentityExchange = record.contextAfter
                and record.contextAfter.dialogue
                and record.contextAfter.dialogue.pendingIdentityExchange,
            engineFacts = Values.copy(record.contextAfter
                and record.contextAfter.engineFacts),
            engineEvents = Values.copy(record.contextAfter
                and record.contextAfter.engineEvents),
        },
        selectedCandidate = {
            patternID = selectedCandidate.patternID,
            score = selectedCandidate.score or selectedCandidate.confidence,
            metadata = Values.copy(selectedCandidate.metadata),
        },
    }
end

return Observation
