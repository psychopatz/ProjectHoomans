-- Bounded flow session storage and transition state helpers.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Kernel = PNC.Semantics.DialogueFlowKernel
local Internal = Kernel.Internal
local copyValue = Internal.CopyValue

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

local function topicForIR(ir)
    if type(ir) ~= "table" then return nil end
    local extensions = type(ir.extensions) == "table"
        and ir.extensions or {}
    local topic = extensions.topic or extensions.dialogueFollowUp
        or ir.subject or ir.action or ir.intent
    if type(topic) == "table" then
        topic = topic.id or topic.key or topic.name
    end
    return topic
end

local function pendingFor(flow, node, topic)
    if type(flow) ~= "table" or type(node) ~= "table"
        or type(node.accepts) ~= "table" or #node.accepts == 0
    then
        return nil
    end
    return {
        id = "flow:" .. tostring(flow.id) .. ":" .. tostring(node.id),
        kind = node.pendingKind or "QUESTION",
        topic = topic or flow.topic or flow.id,
        owner = "flow",
        flowID = flow.id,
        nodeID = node.id,
        requiredSlots = node.requiredSlots,
        sourceFactRefs = node.sourceFactRefs,
    }
end

local function setPending(storage, preview)
    if type(storage) ~= "table"
        or type(preview) ~= "table"
        or type(preview.pendingFollowUp) ~= "table"
        or type(storage.SetPendingFollowUp) ~= "function"
    then
        return false
    end
    local pending = copyValue(preview.pendingFollowUp)
    pending.openedTurn = pending.openedTurn
        or sequenceFor(nil, storage)
    local current = type(storage.GetPendingFollowUp) == "function"
        and storage:GetPendingFollowUp() or nil
    if type(current) == "table"
        and current.id ~= pending.id
        and tostring(current.flowID or "") == tostring(pending.flowID or "")
        and type(storage.CompletePendingFollowUp) == "function"
    then
        -- Advancing within one flow fulfills the prior obligation before
        -- opening its next bounded question/proposal.
        storage:CompletePendingFollowUp("fulfilled", "flow_transition")
    end
    return storage:SetPendingFollowUp(pending)
end

local function completePendingFor(storage, flowID, reason)
    if type(storage) ~= "table"
        or type(storage.GetPendingFollowUp) ~= "function"
        or type(storage.CompletePendingFollowUp) ~= "function"
    then
        return false
    end
    local pending = storage:GetPendingFollowUp()
    if type(pending) ~= "table" or tostring(pending.flowID or "")
        ~= tostring(flowID or "")
    then
        return false
    end
    return storage:CompletePendingFollowUp("fulfilled", reason)
end

Internal.ContextStateFor = contextStateFor
Internal.IdsFor = idsFor
Internal.KeyFor = keyFor
Internal.ReadSession = readSession
Internal.StoreSession = storeSession
Internal.RemoveSession = removeSession
Internal.SequenceFor = sequenceFor
Internal.NodeFor = nodeFor
Internal.TopicForIR = topicForIR
Internal.PendingFor = pendingFor
Internal.SetPending = setPending
Internal.CompletePendingFor = completePendingFor

return Kernel
