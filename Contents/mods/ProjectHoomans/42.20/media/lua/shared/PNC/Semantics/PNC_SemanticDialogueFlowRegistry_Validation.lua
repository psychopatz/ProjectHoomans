-- Dialogue-flow normalization and validation contract.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = PNC.Semantics.DialogueFlowRegistry
local BranchOffers = PNC.Semantics.DialogueBranchOffers
    or require "PNC/Semantics/PNC_SemanticDialogueBranchOffers"
local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"
local copyValue = ValueBounds.Copy

local FRAME_FIELDS = {
    "intent", "speechAct", "action", "subject", "target", "reference",
    "identityClaim", "selfDirected", "stateType", "stateValue", "pattern",
}
local FRAME_FIELD_SET = {}
for index = 1, #FRAME_FIELDS do FRAME_FIELD_SET[FRAME_FIELDS[index]] = true end

local SPECIAL_TARGETS = {
    cancel = true,
    resume = true,
    suspend = true,
}

local GATE_FIELDS = {
    type = true,
    field = true,
    operator = true,
    value = true,
    reasonKey = true,
    unknownReasonKey = true,
    passReasonKey = true,
    failReasonKey = true,
    startHour = true,
    endHour = true,
    gates = true,
    gate = true,
    fact = true,
    subject = true,
    unit = true,
    unknownPolicy = true,
    capabilityID = true,
    requiresTarget = true,
    requiresAuthority = true,
}

local ACTION_FIELDS = {
    capabilityID = true,
    route = true,
    targetScope = true,
    binding = true,
    resultTransitions = true,
    dispatchCount = true,
}

local copyValue = ValueBounds.Copy

local function stringValue(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function frameKey(frame)
    local values = {}
    local index
    local field
    for index = 1, #FRAME_FIELDS do
        field = FRAME_FIELDS[index]
        if frame[field] ~= nil then
            values[#values + 1] = field .. "=" .. tostring(frame[field])
        end
    end
    return table.concat(values, "|")
end

local function normalizeFrame(frame, label)
    if type(frame) ~= "table" then
        return nil, label .. "_must_be_object"
    end
    local output = {}
    local key
    local value
    local supported = false
    for key, value in pairs(frame) do
        if not FRAME_FIELD_SET[key] then
            return nil, label .. "_unsupported_field:" .. tostring(key)
        end
        if type(value) ~= "string"
            and type(value) ~= "number"
            and type(value) ~= "boolean"
        then
            return nil, label .. "_field_must_be_scalar:" .. tostring(key)
        end
        output[key] = value
        supported = true
    end
    if not supported then return nil, label .. "_empty" end
    return output
end

local function normalizeTransition(value, nodes, label)
    if value == nil then return nil end
    value = stringValue(value)
    if not value then return nil, label .. "_empty" end
    if SPECIAL_TARGETS[value] then return value end
    if not nodes[value] then
        return nil, label .. "_unknown_node:" .. value
    end
    return value
end

local function normalizeSlots(slots, label)
    if slots == nil then return {} end
    if type(slots) ~= "table" then return nil, label .. "_must_be_object" end
    local output = {}
    local name
    local definition
    for name, definition in pairs(slots) do
        if type(name) ~= "string" or name == "" then
            return nil, label .. "_invalid_name"
        end
        if type(definition) ~= "table" then
            return nil, label .. "_invalid_slot:" .. name
        end
        local slotType = stringValue(definition.type)
        local owner = stringValue(definition.owner)
        local source = stringValue(definition.source)
        if not slotType or not owner then
            return nil, label .. "_slot_requires_type_and_owner:" .. name
        end
        output[name] = {
            type = slotType,
            owner = owner,
            source = source,
        }
    end
    return output
end

local function normalizeNodeList(values, label)
    if values == nil then return nil end
    if type(values) ~= "table" then
        return nil, label .. "_must_be_array"
    end
    local output = {}
    for index = 1, math.min(#values, 8) do
        local value = stringValue(values[index])
        if not value or #value > 64 then
            return nil, label .. "_item_invalid"
        end
        output[#output + 1] = value
    end
    return output
end

local function normalizeAction(action, nodes, label)
    if action == nil then return nil end
    if type(action) ~= "table" then
        return nil, label .. "_must_be_object"
    end
    local output = {}
    local key
    local value
    for key, value in pairs(action) do
        if not ACTION_FIELDS[key] then
            return nil, label .. "_unsupported_field:" .. tostring(key)
        end
        if key == "binding" then
            if type(value) ~= "table" then
                return nil, label .. "_binding_must_be_object"
            end
            output.binding = copyValue(value)
        elseif key == "resultTransitions" then
            if type(value) ~= "table" then
                return nil, label .. "_result_transitions_must_be_object"
            end
            output.resultTransitions = {}
            for outcome, target in pairs(value) do
                if type(outcome) ~= "string" or type(target) ~= "string"
                    or target == ""
                then
                    return nil, label .. "_invalid_result_transition"
                end
                if not SPECIAL_TARGETS[target] and not nodes[target] then
                    return nil, label .. "_result_unknown_node:" .. target
                end
                output.resultTransitions[outcome] = target
            end
        elseif key == "dispatchCount" then
            if value ~= 1 then
                return nil, label .. "_dispatch_count_must_be_one"
            end
            output.dispatchCount = 1
        else
            if type(value) ~= "string" and type(value) ~= "number"
                and type(value) ~= "boolean"
            then
                return nil, label .. "_field_invalid:" .. tostring(key)
            end
            output[key] = value
        end
    end
    if not output.capabilityID or not output.route
        or type(output.binding) ~= "table"
        or type(output.resultTransitions) ~= "table"
    then
        return nil, label .. "_requires_typed_binding_and_results"
    end
    output.dispatchCount = output.dispatchCount or 1
    return output
end

local function normalizeGate(gate, label)
    if gate == nil then return nil end
    if type(gate) ~= "table" then
        return nil, label .. "_must_be_object"
    end
    local gateType = stringValue(gate.type)
    if not gateType then return nil, label .. "_requires_type" end
    if gateType == "pnc:fact" and not stringValue(gate.fact or gate.subject) then
        return nil, label .. "_fact_required"
    end
    local output = { type = gateType }
    local key
    local value
    for key, value in pairs(gate) do
        if not GATE_FIELDS[key] then
            return nil, label .. "_unsupported_field:" .. tostring(key)
        end
        if key ~= "type" and type(value) ~= "string"
            and type(value) ~= "number"
            and type(value) ~= "boolean"
            and type(value) ~= "table"
        then
            return nil, label .. "_field_invalid:" .. tostring(key)
        end
        output[key] = copyValue(value)
    end
    return output
end

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

return Registry

