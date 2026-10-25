-- Pure flow preview construction and matching orchestration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Kernel = PNC.Semantics.DialogueFlowKernel
local Internal = Kernel.Internal
local Registry = Internal.Registry
local copyValue = Internal.CopyValue
local contextStateFor = Internal.ContextStateFor
local idsFor = Internal.IdsFor
local keyFor = Internal.KeyFor
local readSession = Internal.ReadSession
local nodeFor = Internal.NodeFor
local topicForIR = Internal.TopicForIR
local pendingFor = Internal.PendingFor
local gatedTarget = Internal.GatedTarget
local transitionTarget = Internal.TransitionTarget
local slotValues = Internal.SlotValues
local findTriggeredFlow = Internal.FindTriggeredFlow
local activeMatch = Internal.ActiveMatch
local suspendedMatch = Internal.SuspendedMatch

local function basePreview(ir, speakerID, addresseeID, key)
    local topic = topicForIR(ir)
    return {
        schemaVersion = Kernel.VERSION,
        kind = "semantic_dialogue_flow_preview",
        key = key,
        speakerID = speakerID,
        addresseeID = addresseeID,
        topic = topic,
        matched = false,
        transition = "hold",
        diagnostics = {
            version = Kernel.VERSION,
            registryRevision = Registry.GetRevision(),
            key = key,
            candidateFlows = {},
            topic = topic,
            reason = "no_flow_trigger",
        },
    }
end

local function attachNodeContract(preview, node)
    if type(node) ~= "table" or type(node.action) ~= "table" then
        return
    end
    preview.generated = true
    preview.action = copyValue(node.action)
    preview.capabilityID = node.action.capabilityID
    preview.binding = copyValue(node.action.binding)
    preview.resultTransitions = copyValue(node.action.resultTransitions)
    preview.dispatchCount = node.action.dispatchCount
end

local function attachBranchOffers(preview, node)
    if type(node) ~= "table" then return end
    preview.branchOffers = copyValue(node.branchOffers or {})
    preview.diagnostics.branchOfferCount = #preview.branchOffers
end

local function addMatch(preview, match, transition, fromNodeID, toNodeID)
    local responseNode = match.node
    if transition == "match" or transition == "resume_match" then
        responseNode = nodeFor(match.flow, toNodeID)
    end
    preview.matched = true
    preview.transition = transition
    preview.flowId = match.flow.id
    preview.workflowKind = match.flow.workflowKind
    preview.generated = match.flow.workflowKind ~= nil
    preview.capabilityID = match.flow.capabilityID
    preview.fromNodeId = fromNodeID
    preview.toNodeId = toNodeID
    preview.nodeId = toNodeID
    preview.responsePool = responseNode and responseNode.responsePool or nil
    preview.responseTemplate = responseNode and responseNode.responseTemplate or nil
    attachNodeContract(preview, responseNode)
    attachBranchOffers(preview, responseNode)
    preview.slotValues = slotValues(match.flow, match.node, preview.ir)
    preview.diagnostics.reason = transition
    preview.diagnostics.flowId = match.flow.id
    preview.diagnostics.fromNodeId = fromNodeID
    preview.diagnostics.toNodeId = toNodeID
    preview.pendingFollowUp = pendingFor(
        match.flow,
        nodeFor(match.flow, toNodeID),
        preview.topic
    )
end

local function attachGate(preview, gate)
    if not gate then return end
    preview.gate = copyValue(gate)
    preview.diagnostics.gate = copyValue(gate)
end

local function finalizePreview(preview)
    -- Slot extraction uses the IR only while building the preview. Do not
    -- duplicate the complete IR inside every flow diagnostic/result.
    preview.ir = nil
    return preview
end

function Kernel.Preview(ir, state, context, options)
    context = type(context) == "table" and context or {}
    options = type(options) == "table" and options or {}
    local capabilityCatalog = PNC.Semantics.CapabilityCatalog
    if capabilityCatalog
        and type(capabilityCatalog.EnsureAutomaticGeneration) == "function"
    then
        capabilityCatalog.EnsureAutomaticGeneration()
    end
    local storage = contextStateFor(state, context)
    local speakerID, addresseeID = idsFor(context, options)
    local key = keyFor(storage, speakerID, addresseeID)
    local preview = basePreview(ir, speakerID, addresseeID, key)
    preview.ir = ir
    local session = readSession(storage, key)
    local active = session and session.active
    if active then
        preview.diagnostics.activeFlowId = active.flowId
        preview.diagnostics.activeNodeId = active.nodeId
    end

    local matched = activeMatch(session, ir)
    if matched then
        local target = transitionTarget(matched.node, ir and ir.intent)
        local gate
        target, gate = gatedTarget(matched.flow, target, context)
        addMatch(
            preview,
            matched,
            "match",
            matched.active.nodeId,
            target or "complete"
        )
        attachGate(preview, gate)
        preview.slotValues = slotValues(matched.flow, matched.node, ir)
        return finalizePreview(preview)
    end

    if active and (ir and (ir.intent == "REFUSE" or ir.intent == "DISAGREE"))
        and matched == nil
    then
        local flow = Registry.Get(active.flowId)
        local node = flow and nodeFor(flow, active.nodeId)
        local target = node and node.onRefuse
        if target then
            preview.matched = true
            preview.transition = target == "cancel" and "cancel" or "match"
            preview.flowId = flow.id
            preview.fromNodeId = active.nodeId
            preview.toNodeId = target
            preview.nodeId = target
            preview.diagnostics.reason = preview.transition
            preview.diagnostics.flowId = flow.id
            return finalizePreview(preview)
        end
    end

    local resumed = suspendedMatch(session, ir)
    if resumed then
        local target = transitionTarget(resumed.node, ir and ir.intent)
        local gate
        target, gate = gatedTarget(resumed.flow, target, context)
        addMatch(
            preview,
            resumed,
            "resume_match",
            resumed.active.nodeId,
            target or "complete"
        )
        attachGate(preview, gate)
        preview.suspendedIndex = resumed.index
        preview.slotValues = slotValues(resumed.flow, resumed.node, ir)
        return finalizePreview(preview)
    end

    local triggeredID, triggered = findTriggeredFlow(ir)
    preview.diagnostics.candidateFlows = triggered
    if triggeredID then
        local flow = Registry.Get(triggeredID)
        local target
        local gate
        target, gate = gatedTarget(flow, flow.initial, context)
        local node = nodeFor(flow, target)
        preview.matched = true
        preview.transition = active and active.flowId ~= triggeredID
            and "interrupt_start" or "start"
        preview.flowId = flow.id
        preview.workflowKind = flow.workflowKind
        preview.generated = flow.workflowKind ~= nil
        preview.capabilityID = flow.capabilityID
        preview.fromNodeId = gate and flow.initial
            or (active and active.nodeId or nil)
        preview.toNodeId = target
        preview.nodeId = target
        preview.responsePool = node and node.responsePool or nil
        preview.responseTemplate = node and node.responseTemplate or nil
        attachNodeContract(preview, node)
        attachBranchOffers(preview, node)
        preview.pendingFollowUp = pendingFor(flow, node, preview.topic)
        preview.diagnostics.reason = preview.transition
        preview.diagnostics.flowId = flow.id
        preview.diagnostics.toNodeId = target
        attachGate(preview, gate)
        return finalizePreview(preview)
    end

    if active then preview.diagnostics.reason = "unrelated_preserve_active" end
    return finalizePreview(preview)
end

return Kernel
