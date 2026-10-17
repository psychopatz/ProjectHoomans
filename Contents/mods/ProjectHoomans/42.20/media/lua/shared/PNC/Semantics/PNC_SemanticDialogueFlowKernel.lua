-- Minimal bounded dialogue-flow preview/commit kernel.
--
-- Preview only calculates a transition. Commit is the sole mutation path and
-- stores bounded flow state inside the existing dialogue context object.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = require
    "PNC/Semantics/PNC_SemanticDialogueFlowCatalog"

local Kernel = PNC.Semantics.DialogueFlowKernel or {}
PNC.Semantics.DialogueFlowKernel = Kernel

Kernel.VERSION = 1
Kernel.DEFAULT_MAX_STACK = 4
Kernel.DEFAULT_MAX_FLOWS = 8
Kernel.MAX_DIAGNOSTIC_CANDIDATES = 8

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 10 then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = copyValue(item, depth + 1)
        end
    end
    return output
end

local function contextStateFor(state, context)
    if type(context) == "table"
        and type(context.semanticContextState) == "table"
    then
        return context.semanticContextState
    end
    return state
end

local function idsFor(context, options)
    context = type(context) == "table" and context or {}
    options = type(options) == "table" and options or {}
    local speakerID = options.speakerID or context.speakerID
        or context.playerUUID or context.characterUUID or "player"
    local addresseeID = options.addresseeID or context.addresseeID
        or context.npcUUID or context.npcID or "npc"
    return tostring(speakerID), tostring(addresseeID)
end

local function keyFor(storage, speakerID, addresseeID)
    if storage and type(storage.MakeFlowKey) == "function" then
        return storage.MakeFlowKey(speakerID, addresseeID)
    end
    return tostring(speakerID) .. "|" .. tostring(addresseeID)
end

local function readSession(storage, key)
    if type(storage) ~= "table" then return nil end
    if type(storage.GetFlowSession) == "function" then
        return storage:GetFlowSession(key)
    end
    return copyValue(storage.flowSessions and storage.flowSessions[key])
end

local function storeSession(storage, session)
    if type(storage) ~= "table" then return false, "flow_state_unavailable" end
    if type(storage.StoreFlowSession) == "function" then
        return storage:StoreFlowSession(session)
    end
    storage.flowSessions = storage.flowSessions or {}
    storage.flowOrder = storage.flowOrder or {}
    storage.maxFlows = tonumber(storage.maxFlows) or Kernel.DEFAULT_MAX_FLOWS
    local key = session.key
    if not storage.flowSessions[key] then
        while #storage.flowOrder >= storage.maxFlows do
            local retired = table.remove(storage.flowOrder, 1)
            storage.flowSessions[retired] = nil
        end
        storage.flowOrder[#storage.flowOrder + 1] = key
    end
    storage.flowSessions[key] = copyValue(session)
    return true, storage.flowSessions[key]
end

local function removeSession(storage, key)
    if type(storage) ~= "table" then return false end
    if type(storage.RemoveFlowSession) == "function" then
        return storage:RemoveFlowSession(key)
    end
    if not storage.flowSessions or not storage.flowSessions[key] then
        return false
    end
    storage.flowSessions[key] = nil
    for index = #(storage.flowOrder or {}), 1, -1 do
        if storage.flowOrder[index] == key then
            table.remove(storage.flowOrder, index)
        end
    end
    return true
end

local function sequenceFor(state, storage)
    return (tonumber(state and state.sequence)
        or tonumber(storage and storage.sequence) or 0) + 1
end

local function nodeFor(flow, nodeID)
    return flow and flow.nodes and flow.nodes[nodeID] or nil
end

local function transitionTarget(node, intent)
    if not node then return nil end
    if intent == "REFUSE" or intent == "DISAGREE" then
        return node.onRefuse or node.onMatch or node.next
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

local function basePreview(ir, speakerID, addresseeID, key)
    return {
        schemaVersion = Kernel.VERSION,
        kind = "semantic_dialogue_flow_preview",
        key = key,
        speakerID = speakerID,
        addresseeID = addresseeID,
        matched = false,
        transition = "hold",
        diagnostics = {
            version = Kernel.VERSION,
            registryRevision = Registry.GetRevision(),
            key = key,
            candidateFlows = {},
            reason = "no_flow_trigger",
        },
    }
end

local function addMatch(preview, match, transition, fromNodeID, toNodeID)
    preview.matched = true
    preview.transition = transition
    preview.flowId = match.flow.id
    preview.fromNodeId = fromNodeID
    preview.toNodeId = toNodeID
    preview.nodeId = toNodeID
    preview.responsePool = match.node.responsePool
    preview.responseTemplate = match.node.responseTemplate
    preview.slotValues = slotValues(match.flow, match.node, preview.ir)
    preview.diagnostics.reason = transition
    preview.diagnostics.flowId = match.flow.id
    preview.diagnostics.fromNodeId = fromNodeID
    preview.diagnostics.toNodeId = toNodeID
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
        addMatch(
            preview,
            matched,
            "match",
            matched.active.nodeId,
            target or "complete"
        )
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
        addMatch(
            preview,
            resumed,
            "resume_match",
            resumed.active.nodeId,
            target or "complete"
        )
        preview.suspendedIndex = resumed.index
        preview.slotValues = slotValues(resumed.flow, resumed.node, ir)
        return finalizePreview(preview)
    end

    local triggeredID, triggered = findTriggeredFlow(ir)
    preview.diagnostics.candidateFlows = triggered
    if triggeredID then
        local flow = Registry.Get(triggeredID)
        local node = nodeFor(flow, flow.initial)
        preview.matched = true
        preview.transition = active and active.flowId ~= triggeredID
            and "interrupt_start" or "start"
        preview.flowId = flow.id
        preview.fromNodeId = active and active.nodeId or nil
        preview.toNodeId = flow.initial
        preview.nodeId = flow.initial
        preview.responsePool = node and node.responsePool or nil
        preview.responseTemplate = node and node.responseTemplate or nil
        preview.diagnostics.reason = preview.transition
        preview.diagnostics.flowId = flow.id
        preview.diagnostics.toNodeId = flow.initial
        return finalizePreview(preview)
    end

    if active then preview.diagnostics.reason = "unrelated_preserve_active" end
    return finalizePreview(preview)
end

local function newSession(preview, sequence)
    return {
        key = preview.key,
        speakerID = preview.speakerID,
        addresseeID = preview.addresseeID,
        active = {
            flowId = preview.flowId,
            nodeId = preview.toNodeId,
            slots = {},
            startedAt = sequence,
            lastSequence = sequence,
        },
        suspended = {},
        revision = 1,
        lastTransition = preview.transition,
    }
end

local function pushActive(session, maximum)
    if not session.active then return end
    session.suspended = session.suspended or {}
    session.suspended[#session.suspended + 1] = copyValue(session.active)
    while #session.suspended > maximum do table.remove(session.suspended, 1) end
end

local function completeActive(session, preview)
    local completed = session.active and session.active.flowId or nil
    session.active = nil
    session.completedFlowId = completed
    if preview.suspendedIndex then
        table.remove(session.suspended, preview.suspendedIndex)
    end
    if not session.active and #session.suspended > 0 then
        session.active = table.remove(session.suspended)
        session.resumedFlowId = session.active.flowId
    end
end

function Kernel.Commit(preview, ir, state, context, options)
    options = type(options) == "table" and options or {}
    if type(preview) ~= "table"
        or preview.kind ~= "semantic_dialogue_flow_preview"
    then
        return nil, "invalid_flow_preview"
    end
    local storage = contextStateFor(state, context)
    if not storage then return nil, "flow_state_unavailable" end
    local sequence = sequenceFor(state, storage)
    local session = readSession(storage, preview.key)
    local maximum = tonumber(
        storage.maxFlowStack or options.maxFlowStack
    ) or Kernel.DEFAULT_MAX_STACK
    local result = copyValue(preview)
    result.committed = true
    result.commitSequence = sequence

    if preview.transition == "hold" then
        result.status = "held"
        return result
    end

    if preview.transition == "start"
        or preview.transition == "interrupt_start"
    then
        if not session then
            session = newSession(preview, sequence)
        elseif preview.transition == "interrupt_start" then
            pushActive(session, maximum)
            session.active = {
                flowId = preview.flowId,
                nodeId = preview.toNodeId,
                slots = {},
                startedAt = sequence,
                lastSequence = sequence,
            }
            session.revision = (tonumber(session.revision) or 0) + 1
        else
            session.active = session.active or {
                flowId = preview.flowId,
                nodeId = preview.toNodeId,
                slots = {},
                startedAt = sequence,
            }
            session.active.nodeId = preview.toNodeId
            session.active.lastSequence = sequence
        end
        session.lastTransition = preview.transition
        storeSession(storage, session)
        result.status = "started"
        result.active = copyValue(session.active)
        result.suspended = copyValue(session.suspended)
        return result
    end

    if not session then
        result.committed = false
        result.status = "stale_flow_session"
        return result
    end

    if preview.transition == "resume_match" and preview.suspendedIndex then
        local resumed = table.remove(session.suspended, preview.suspendedIndex)
        -- The resumed entry is already removed from the suspended stack. Keep
        -- the preview index only as diagnostic evidence; do not let the
        -- completion path remove a second stack entry.
        local completionPreview = copyValue(preview)
        completionPreview.suspendedIndex = nil
        if resumed then
            if session.active then
                session.suspended[#session.suspended + 1] = session.active
                while #session.suspended > maximum do
                    table.remove(session.suspended, 1)
                end
            end
            session.active = resumed
        end
        preview = completionPreview
    end

    if preview.transition == "cancel" then
        completeActive(session, preview)
    elseif session.active then
        session.active.nodeId = preview.toNodeId
        session.active.lastSequence = sequence
        session.active.slots = session.active.slots or {}
        for name, value in pairs(preview.slotValues or {}) do
            session.active.slots[name] = copyValue(value)
        end
        local flow = Registry.Get(session.active.flowId)
        local node = flow and nodeFor(flow, session.active.nodeId)
        if preview.toNodeId == "complete"
            or preview.toNodeId == "cancel"
            or node and node.terminal == true
        then
            completeActive(session, preview)
        end
    end

    session.lastTransition = preview.transition
    if session.active or #session.suspended > 0 then
        session.revision = (tonumber(session.revision) or 0) + 1
        storeSession(storage, session)
        result.status = "advanced"
        result.active = copyValue(session.active)
        result.suspended = copyValue(session.suspended)
    else
        removeSession(storage, preview.key)
        result.status = "retired"
        result.active = nil
        result.suspended = {}
    end
    return result
end

function Kernel.Snapshot(state, context)
    local storage = contextStateFor(state, context)
    if type(storage) ~= "table" then return {} end
    if type(storage.FlowSnapshot) == "function" then
        return storage:FlowSnapshot()
    end
    local output = {}
    for index = 1, #(storage.flowOrder or {}) do
        local key = storage.flowOrder[index]
        if storage.flowSessions and storage.flowSessions[key] then
            output[#output + 1] = copyValue(storage.flowSessions[key])
        end
    end
    return output
end

return Kernel
