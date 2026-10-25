-- Reachability checks for normalized dialogue-flow graphs.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Normalization = require
    "PNC/Semantics/PNC_SemanticDialogueFlowRegistry_Validation_Normalization"
local SPECIAL_TARGETS = Normalization.SpecialTargets

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

return {
    Validate = validateReachability,
}

