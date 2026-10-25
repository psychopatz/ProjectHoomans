-- Dialogue-flow node normalization.
-- Primitive scalar/table checks live in a separate module so this module owns
-- only node-level composition and the branch-offer contract.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = PNC.Semantics.DialogueFlowRegistry
local BranchOffers = PNC.Semantics.DialogueBranchOffers
    or require "PNC/Semantics/PNC_SemanticDialogueBranchOffers"
local Primitives = require
    "PNC/Semantics/PNC_SemanticDialogueFlowRegistry_Validation_Primitives"

local stringValue = Primitives.StringValue
local frameKey = Primitives.FrameKey
local normalizeFrame = Primitives.NormalizeFrame
local normalizeTransition = Primitives.NormalizeTransition
local normalizeSlots = Primitives.NormalizeSlots
local normalizeNodeList = Primitives.NormalizeNodeList
local normalizeAction = Primitives.NormalizeAction
local normalizeGate = Primitives.NormalizeGate

local function normalizeNode(nodeID, node, nodes)
    if type(node) ~= "table" then
        return nil, "node_must_be_object:" .. tostring(nodeID)
    end
    local output = {
        id = nodeID,
        terminal = node.terminal == true,
        responsePool = stringValue(node.responsePool),
        responseTemplate = stringValue(node.responseTemplate),
    }
    local requiredSlots, requiredSlotsReason = normalizeNodeList(
        node.requiredSlots, "node_required_slots"
    )
    if node.requiredSlots ~= nil and not requiredSlots then
        return nil, requiredSlotsReason .. ":" .. tostring(nodeID)
    end
    local sourceFactRefs, sourceFactRefsReason = normalizeNodeList(
        node.sourceFactRefs, "node_source_fact_refs"
    )
    if node.sourceFactRefs ~= nil and not sourceFactRefs then
        return nil, sourceFactRefsReason .. ":" .. tostring(nodeID)
    end
    output.requiredSlots = requiredSlots
    output.sourceFactRefs = sourceFactRefs
    local pendingKind = stringValue(node.pendingKind)
    if node.pendingKind ~= nil and (not pendingKind or #pendingKind > 32) then
        return nil, "node_pending_kind_invalid:" .. tostring(nodeID)
    end
    output.pendingKind = pendingKind
    local gate, reason = normalizeGate(node.gate, "node_gate")
    if node.gate ~= nil and not gate then return nil, reason end
    output.gate = gate
    local slots
    slots, reason = normalizeSlots(node.slots, "node_slots")
    if not slots then return nil, reason .. ":" .. tostring(nodeID) end
    output.slots = slots

    local offers, offersReason = BranchOffers.NormalizeList(
        node.branchOffers, "node_branch_offers", Registry.MAX_OFFERS
    )
    if node.branchOffers ~= nil and not offers then
        return nil, offersReason .. ":" .. tostring(nodeID)
    end
    output.branchOffers = offers

    local action, actionReason = normalizeAction(
        node.action, nodes, "node_action"
    )
    if node.action ~= nil and not action then return nil, actionReason end
    output.action = action

    if node.accepts ~= nil then
        if type(node.accepts) ~= "table" then
            return nil, "node_accepts_must_be_array:" .. tostring(nodeID)
        end
        if #node.accepts > Registry.MAX_ACCEPTS then
            return nil, "node_accept_limit:" .. tostring(nodeID)
        end
        output.accepts = {}
        local seen = {}
        local index
        local frame
        local key
        for index = 1, #node.accepts do
            frame, reason = normalizeFrame(
                node.accepts[index], "node_accept_frame"
            )
            if not frame then return nil, reason .. ":" .. tostring(nodeID) end
            key = frameKey(frame)
            if seen[key] then
                return nil, "duplicate_node_transition:" .. tostring(nodeID)
            end
            seen[key] = true
            output.accepts[#output.accepts + 1] = frame
        end
    else
        output.accepts = {}
    end

    local fields = {
        "next", "onMatch", "onUnrelated", "onRefuse",
        "onClarify", "onPass", "onFail", "onUnknown",
    }
    local index
    local field
    local target
    for index = 1, #fields do
        field = fields[index]
        target, reason = normalizeTransition(
            node[field], nodes, "node_" .. field
        )
        if node[field] ~= nil and not target then
            return nil, reason .. ":" .. tostring(nodeID)
        end
        output[field] = target
    end
    if not output.terminal and #output.accepts == 0 and not output.gate then
        return nil, "nonterminal_node_requires_accepts:" .. tostring(nodeID)
    end
    if not output.terminal
        and not output.next and not output.onMatch
        and not output.onUnrelated and not output.onRefuse
        and not output.onPass and not output.onFail
        and not output.onUnknown
        and not output.action
    then
        return nil, "nonterminal_node_requires_transition:" .. tostring(nodeID)
    end
    return output
end

local function validateReachability(nodes, initial)
    local seen = {}
    local pending = { initial }
    local index
    local nodeID
    local node
    local target
    while #pending > 0 do
        nodeID = table.remove(pending, 1)
        if not seen[nodeID] then
            seen[nodeID] = true
            node = nodes[nodeID]
            if node then
        for _, field in ipairs({
            "next", "onMatch", "onClarify", "onRefuse",
            "onPass", "onFail", "onUnknown",
        }) do
                    target = node[field]
                    if target and not SPECIAL_TARGETS[target]
                        and not seen[target]
                    then
                        pending[#pending + 1] = target
                    end
                end
                if node.action
                    and type(node.action.resultTransitions) == "table"
                then
                    for _, target in pairs(node.action.resultTransitions) do
                        if target and not SPECIAL_TARGETS[target]
                            and not seen[target]
                        then
                            pending[#pending + 1] = target
                        end
                    end
                end
            end
        end
    end
    for nodeID in pairs(nodes) do
        if not seen[nodeID] then
            return false, "unreachable_node:" .. tostring(nodeID)
        end
    end
    return true
end

function Registry.Validate(definition)
    if type(definition) ~= "table" then return false, "flow_must_be_object" end
    local flowID = stringValue(definition.id)
    if not flowID then return false, "flow_requires_id" end
    if string.find(flowID, "[%s/]") then
        return false, "flow_id_contains_separator"
    end
    local version = tonumber(definition.version) or 0
    if version < 1 then return false, "flow_requires_version" end
    if type(definition.triggers) ~= "table"
        or #definition.triggers == 0
    then
        return false, "flow_requires_triggers"
    end
    if #definition.triggers > Registry.MAX_TRIGGERS then
        return false, "flow_trigger_limit"
    end
    local normalizedTriggers = {}
    local index
    local frame
    local reason
    for index = 1, #definition.triggers do
        frame, reason = normalizeFrame(
            definition.triggers[index], "flow_trigger"
        )
        if not frame then return false, reason end
        normalizedTriggers[#normalizedTriggers + 1] = frame
    end

    if type(definition.nodes) ~= "table" then
        return false, "flow_requires_nodes"
    end
    local nodeCount = 0
    local nodeID
    for nodeID in pairs(definition.nodes) do nodeCount = nodeCount + 1 end
    if nodeCount == 0 then return false, "flow_requires_nodes" end
    if nodeCount > Registry.MAX_NODES then return false, "flow_node_limit" end
    local initial = stringValue(definition.initial)
    if not initial or not definition.nodes[initial] then
        return false, "flow_initial_node_missing"
    end

    local normalizedNodes = {}
    for nodeID in pairs(definition.nodes) do
        if type(nodeID) ~= "string" or nodeID == "" then
            return false, "flow_invalid_node_id"
        end
    end
    for nodeID, node in pairs(definition.nodes) do
        normalizedNodes[nodeID], reason = normalizeNode(
            nodeID, node, definition.nodes
        )
        if not normalizedNodes[nodeID] then return false, reason end
    end
    local reachable
    reachable, reason = validateReachability(normalizedNodes, initial)
    if not reachable then return false, reason end

    local slotOwners = {}
    for nodeID, node in pairs(normalizedNodes) do
        local slotName
        local slot
        for slotName, slot in pairs(node.slots) do
            if slotOwners[slotName]
                and slotOwners[slotName] ~= slot.owner
            then
                return false, "conflicting_slot_owner:" .. slotName
            end
            slotOwners[slotName] = slot.owner
        end
    end

    return true, {
        id = flowID,
        version = version,
        owner = stringValue(definition.owner),
        workflowKind = stringValue(definition.workflowKind),
        templateVersion = tonumber(definition.templateVersion),
        capabilityID = stringValue(definition.capabilityID),
        initial = initial,
        triggers = normalizedTriggers,
        nodes = normalizedNodes,
        slotOwners = slotOwners,
    }
end

return {
    StringValue = stringValue,
    NormalizeFrame = normalizeFrame,
    NormalizeNode = normalizeNode,
    SpecialTargets = Primitives.SpecialTargets,
}



