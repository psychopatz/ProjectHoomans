-- Semantic flow and hub graph projections.

local Graph = {}

local function addGraphValue(values, seen, value)
    value = tostring(value or "")
    if value ~= "" and not seen[value] then
        seen[value] = true
        values[#values + 1] = value
    end
end

local function semanticFlowGraphProjection(view)
    local suggestions = view and view.semanticSuggestions or nil
    local activeFlow = suggestions and suggestions.activeFlow or nil
    local result = view and view.lastSemanticDialogueResult or nil
    local flow = result and result.flow or nil
    if type(flow) ~= "table" then flow = {} end
    local flowID = activeFlow and activeFlow.flowID or flow.flowId
    if not flowID or tostring(flowID) == "" then return nil end
    local registry = PNC.Semantics and PNC.Semantics.DialogueFlowRegistry
    local definition = registry and type(registry.Get) == "function"
        and registry.Get(flowID) or nil
    if type(definition) ~= "table" or type(definition.nodes) ~= "table" then
        return nil
    end

    local currentNodeID = activeFlow and activeFlow.nodeID
        or flow.toNodeId or flow.nodeId
    currentNodeID = tostring(currentNodeID or "")
    local completed = flow.status == "completed"
        or flow.completedFlowId ~= nil
    local visited = {}
    local visitedIDs = {}
    for _, group in ipairs({ flow.activeBefore, flow.activeAfter }) do
        for _, session in ipairs(group or {}) do
            if type(session) == "table" then
                local nodeID = session.nodeId or session.nodeID
                addGraphValue(visitedIDs, visited, nodeID)
            end
        end
    end
    addGraphValue(visitedIDs, visited, currentNodeID)

    local nodeIDs = {}
    for nodeID in pairs(definition.nodes) do
        nodeIDs[#nodeIDs + 1] = tostring(nodeID)
    end
    table.sort(nodeIDs)
    local nodeSet = {}
    for _, nodeID in ipairs(nodeIDs) do nodeSet[nodeID] = true end
    local nodes = {}
    local edges = {}
    local available = {}
    local transitionFields = {
        "onMatch", "onRefuse", "onUnrelated", "onPass", "onFail",
        "onUnknown", "onSuccess", "onFailure", "onCancel", "onTimeout",
    }
    for _, nodeID in ipairs(nodeIDs) do
        local node = definition.nodes[nodeID] or {}
        local choices = {}
        for _, offer in ipairs(node.branchOffers or {}) do
            if type(offer) == "table" then
                choices[#choices + 1] = {
                    id = offer.id,
                    text = offer.label or offer.id,
                    enabled = true,
                }
            end
        end
        nodes[#nodes + 1] = {
            id = nodeID,
            title = node.title or nodeID,
            npcText = node.responsePool or node.responseTemplate or "",
            state = completed and nodeID == currentNodeID and "completed"
                or nodeID == currentNodeID and "current"
                or visited[nodeID] and "visited" or "future",
            current = nodeID == currentNodeID,
            visited = visited[nodeID] == true,
            choices = choices,
            terminal = node.terminal == true,
            source = { flowID = flowID, nodeID = nodeID },
        }
        for _, field in ipairs(transitionFields) do
            local target = node[field]
            if target ~= nil and tostring(target) ~= "" then
                target = tostring(target)
                if nodeID == currentNodeID and nodeSet[target] then
                    available[target] = true
                end
                edges[#edges + 1] = {
                    id = "semantic_flow:" .. tostring(flowID) .. ":"
                        .. nodeID .. ":" .. field,
                    fromNodeID = nodeID,
                    toNodeID = target,
                    field = field,
                    label = field,
                    state = nodeID == currentNodeID and nodeSet[target]
                        and "available" or "future",
                    internal = nodeSet[target] == true,
                    clickable = false,
                }
            end
        end
    end
    for _, node in ipairs(nodes) do
        if node.state == "future" and available[node.id] then
            node.state = "available"
        end
    end
    return {
        schema = "semantic_lab.graph.v1",
        schemaVersion = 1,
        graphKind = "semantic_flow",
        graphID = "semantic_flow:" .. tostring(flowID),
        title = tostring(flowID),
        flowID = tostring(flowID),
        initial = definition.initial,
        currentNodeID = currentNodeID,
        visitedNodeIDs = visitedIDs,
        revision = suggestions and suggestions.revision,
        generated = definition.workflowKind ~= nil,
        workflowKind = definition.workflowKind,
        triggers = definition.triggers or {},
        nodes = nodes,
        edges = edges,
        rootExits = {},
    }
end

local function semanticHubGraphProjection(view)
    local suggestions = view and view.semanticSuggestions or nil
    local hub = suggestions and suggestions.activeHub or nil
    local history = view.semanticHubGraphHistory
        or { ids = {}, ordered = {}, candidates = {}, completed = {}, hubID = nil }
    view.semanticHubGraphHistory = history
    history.completed = history.completed or {}
    history.candidates = history.candidates or {}
    if type(hub) == "table" and hub.id then
        history.hubID = tostring(hub.id)
        for _, candidate in ipairs(suggestions.candidates or {}) do
            if type(candidate) == "table" and candidate.id then
                history.candidates[tostring(candidate.id)] = candidate
            end
        end
    elseif history.hubID then
        hub = { id = history.hubID }
    else
        return nil
    end
    local result = view.lastSemanticDialogueResult or {}
    local selected = result.selectedCandidate
        or result.selected
        or result.candidate
    local selectedID = type(selected) == "table"
        and (selected.id or selected.candidateID) or nil
    if not selectedID and type(result.ir) == "table"
        and type(result.ir.provenance) == "table"
    then
        selectedID = result.ir.provenance.candidateID
    end
    if selectedID and not history.ids[tostring(selectedID)] then
        history.ids[tostring(selectedID)] = true
        history.ordered[#history.ordered + 1] = tostring(selectedID)
    end
    if selectedID then
        history.completed[tostring(selectedID)] = true
    end

    local rootID = "hub:" .. tostring(hub.id)
    local nodes = {
        {
            id = rootID,
            title = tostring(hub.id),
            npcText = "Contextual semantic hub",
            state = "current",
            current = true,
            visited = true,
            choices = {},
            terminal = false,
        },
    }
    local edges = {}
    local candidateRows = {}
    if suggestions and suggestions.activeHub
        and type(suggestions.candidates) == "table"
    then
        for _, candidate in ipairs(suggestions.candidates) do
            candidateRows[#candidateRows + 1] = candidate
        end
    else
        for _, candidate in pairs(history.candidates or {}) do
            candidateRows[#candidateRows + 1] = candidate
        end
        table.sort(candidateRows, function(left, right)
            return tostring(left.id) < tostring(right.id)
        end)
    end
    for _, candidate in ipairs(candidateRows) do
        if type(candidate) == "table" and candidate.id then
            local candidateID = "candidate:" .. tostring(candidate.id)
            local display = candidate.display or {}
            local label = display.label or display.labelFallback
                or candidate.labelFallback or candidate.id
            local visited = history.ids[tostring(candidate.id)] == true
            local enabled = candidate.enabled ~= false
                and (candidate.eligibility or {}).status ~= "blocked"
            if not suggestions or not suggestions.activeHub then
                enabled = false
            end
            nodes[#nodes + 1] = {
                id = candidateID,
                title = tostring(label),
                npcText = candidate.utteranceFallback or "",
                state = history.completed[tostring(candidate.id)] and "completed"
                    or visited and "visited"
                    or enabled and "available" or "locked",
                current = false,
                visited = visited,
                choices = {},
                terminal = false,
                source = {
                    candidateID = candidate.id,
                    providerID = candidate.providerID,
                },
            }
            edges[#edges + 1] = {
                id = "semantic_hub:" .. tostring(hub.id) .. ":"
                    .. tostring(candidate.id),
                fromNodeID = rootID,
                toNodeID = candidateID,
                field = "candidate",
                label = tostring(label),
                state = history.completed[tostring(candidate.id)] and "completed"
                    or visited and "visited"
                    or enabled and "available" or "locked",
                internal = true,
                clickable = enabled,
                frame = type(candidate.frame) == "table"
                    and candidate.frame or nil,
            }
        end
    end
    return {
        schema = "semantic_lab.graph.v1",
        schemaVersion = 1,
        graphKind = "semantic_hub",
        graphID = "semantic_hub:" .. tostring(hub.id) .. ":"
            .. tostring(suggestions and suggestions.revision or 0),
        title = tostring(hub.id),
        flowID = "semantic_hub:" .. tostring(hub.id),
        initial = rootID,
        currentNodeID = rootID,
        visitedNodeIDs = history.ordered,
        revision = suggestions and suggestions.revision,
        generated = false,
        triggers = {},
        nodes = nodes,
        edges = edges,
        rootExits = {},
    }
end

function Graph.project(view)
    local composer = PNC.Conversation and PNC.Conversation.Composer
    if composer
        and type(composer.BuildSemanticConversationGraphProjection)
            == "function"
    then
        local graph = composer.BuildSemanticConversationGraphProjection(view)
        if graph then return graph end
    end
    return semanticFlowGraphProjection(view)
        or semanticHubGraphProjection(view)
end

return Graph
