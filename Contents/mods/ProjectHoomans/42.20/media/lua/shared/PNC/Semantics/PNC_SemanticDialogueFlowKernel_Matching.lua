-- Flow matching, gate evaluation, and slot extraction.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Kernel = PNC.Semantics.DialogueFlowKernel
local Internal = Kernel.Internal
local Rules = Internal.Rules
local Registry = Internal.Registry
local copyValue = Internal.CopyValue
local nodeFor = Internal.NodeFor

local function gateResult(flow, node, context)
    if not node or not node.gate then return nil end
    local status
    local reason
    if type(Rules.EvaluateGateStatus) == "function" then
        status, reason = Rules.EvaluateGateStatus(node.gate, context)
    else
        return {
            nodeId = node.id,
            type = node.gate.type,
            status = "UNKNOWN",
            reason = "gate_evaluator_unavailable",
        }
    end
    return {
        nodeId = node.id,
        type = node.gate.type,
        status = status,
        reason = reason,
    }
end

local function gatedTarget(flow, nodeID, context)
    local currentID = nodeID
    local current = nodeFor(flow, currentID)
    local lastGate
    local seen = {}
    while current and current.gate do
        if seen[currentID] then
            return currentID, {
                nodeId = currentID,
                type = current.gate.type,
                status = "UNKNOWN",
                reason = "gate_cycle",
            }
        end
        seen[currentID] = true
        lastGate = gateResult(flow, current, context)
        local field = lastGate.status == "PASS" and "onPass"
            or lastGate.status == "FAIL" and "onFail" or "onUnknown"
        local target = current[field]
        if not target or target == "cancel"
            or target == "resume" or target == "suspend"
        then
            return currentID, lastGate
        end
        currentID = target
        current = nodeFor(flow, currentID)
    end
    return currentID, lastGate
end

local function transitionTarget(node, intent)
    if not node then return nil end
    if intent == "REFUSE" or intent == "DISAGREE" then
        return node.onRefuse or node.onMatch or node.next
    end
    if intent == "CLARIFY" or intent == "ASK_FOR_CLARIFICATION" then
        return node.onClarify or node.onMatch or node.next
    end
    return node.onMatch or node.next
end

local function readPath(value, path)
    if type(value) ~= "table" or type(path) ~= "string" then return nil end
    local current = value
    local part
    for part in string.gmatch(path, "[^%.]+") do
        if type(current) ~= "table" then return nil end
        current = current[part]
    end
    return current
end

local function slotValues(flow, node, ir)
    local output = {}
    if not node or type(node.slots) ~= "table" then return output end
    local name
    local definition
    local value
    for name, definition in pairs(node.slots) do
        value = definition.source and readPath(ir, definition.source)
            or ir.slots and ir.slots[name]
        if value ~= nil then
            output[name] = {
                type = definition.type,
                owner = definition.owner,
                source = definition.source,
                value = copyValue(value),
            }
        end
    end
    return output
end

local function flowTrigger(flow, ir)
    local matches = Registry.MatchesAny(flow and flow.triggers, ir)
    return matches == true
end

local function findTriggeredFlow(ir)
    local flowID
    local flow
    local candidates = {}
    for _, registeredID in ipairs(Registry.List()) do
        flowID = registeredID
        flow = Registry.Get(flowID)
        if flowTrigger(flow, ir) then
            candidates[#candidates + 1] = flowID
        end
    end
    return candidates[1], candidates
end

local function activeMatch(session, ir)
    local active = session and session.active
    local flow = active and Registry.Get(active.flowId)
    local node = flow and nodeFor(flow, active.nodeId)
    if not active or not flow or not node then return nil end
    local matches = Registry.MatchesAny(node.accepts, ir)
    if not matches then return nil end
    return {
        flow = flow,
        node = node,
        active = active,
        index = nil,
    }
end

local function suspendedMatch(session, ir)
    local suspended = session and session.suspended or {}
    local index
    local entry
    local flow
    local node
    for index = #suspended, 1, -1 do
        entry = suspended[index]
        flow = entry and Registry.Get(entry.flowId)
        node = flow and nodeFor(flow, entry.nodeId)
        if flow and node and Registry.MatchesAny(node.accepts, ir) then
            return {
                flow = flow,
                node = node,
                active = entry,
                index = index,
            }
        end
    end
    return nil
end

Internal.GateResult = gateResult
Internal.GatedTarget = gatedTarget
Internal.TransitionTarget = transitionTarget
Internal.ReadPath = readPath
Internal.SlotValues = slotValues
Internal.FlowTrigger = flowTrigger
Internal.FindTriggeredFlow = findTriggeredFlow
Internal.ActiveMatch = activeMatch
Internal.SuspendedMatch = suspendedMatch

return Kernel
