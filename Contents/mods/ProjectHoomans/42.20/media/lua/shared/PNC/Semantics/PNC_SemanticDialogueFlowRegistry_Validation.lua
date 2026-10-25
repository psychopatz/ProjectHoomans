-- Dialogue-flow validation facade.
-- The public Registry.Validate contract stays here while normalization and
-- graph checks remain independently testable and bounded.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = PNC.Semantics.DialogueFlowRegistry
local Normalization = require
    "PNC/Semantics/PNC_SemanticDialogueFlowRegistry_Validation_Normalization"
local Reachability = require
    "PNC/Semantics/PNC_SemanticDialogueFlowRegistry_Validation_Reachability"
local stringValue = Normalization.StringValue
local normalizeFrame = Normalization.NormalizeFrame

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
        normalizedNodes[nodeID], reason = Normalization.NormalizeNode(
            nodeID, node, definition.nodes
        )
        if not normalizedNodes[nodeID] then return false, reason end
    end
    local reachable
    reachable, reason = Reachability.Validate(normalizedNodes, initial)
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
