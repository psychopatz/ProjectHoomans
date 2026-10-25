local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Selector = Conversation.Selector
local Internal = Composer.Internal
local Registry = Conversation.Registry
local TopicCatalog = Internal.TopicCatalog

local dialoguePayload = Internal.DialoguePayload
local lockedText = Internal.LockedText
local resolveProjectionText = Internal.ResolveProjectionText

local function sourceProjection(source)
    source = type(source) == "table" and source or {}
    return {
        modID = source.modID,
        domain = source.domain,
        pathPattern = source.pathPattern,
    }
end

local function containsID(values, requested)
    if type(values) == "table" then
        if values[requested] == true
            or values["block:" .. tostring(requested)] == true
        then
            return true
        end
    end
    for _, value in ipairs(values or {}) do
        if tostring(value) == tostring(requested) then return true end
    end
    return false
end

-- Developer-only read projection of the complete selected authored block.
-- This deliberately does not replace BuildSemanticBlockProjection: the normal
-- player-facing surface must remain bounded to the current node.  The graph
-- is derived from the authoritative registry and live context on demand and
-- carries no state of its own.
local function normalizeGraphNodeID(nodeID)
    nodeID = tostring(nodeID or "")
    if string.sub(nodeID, 1, 6) == "block:" then
        nodeID = string.sub(nodeID, 7)
    end
    return nodeID
end

local function graphRevision(view, session)
    local router = session and session.semanticDialogueRouter
    local revision = router and router.state
        and tonumber(router.state.sequence) or 0
    if view and view.semanticSuggestions then
        revision = tonumber(view.semanticSuggestions.revision) or revision
    end
    return revision
end

local function graphTopic(block)
    local topicCatalog = PNC.Semantics and PNC.Semantics.TopicCatalog
        or TopicCatalog
    return topicCatalog
        and type(topicCatalog.AuthoredTopic) == "function"
        and topicCatalog.AuthoredTopic(block) or block.topic
end

local function graphOutcomes(block, nodeID, choice)
    local outcomes = {}
    local targets = {}
    local targetRows = {}
    for _, outcome in ipairs(choice.outcomes or {}) do
        local target = tostring(outcome.next or "$root")
        local outcomeID = tostring(outcome.id or "")
        outcomes[#outcomes + 1] = {
            id = outcomeID,
            weight = tonumber(outcome.weight) or 1,
            nextNodeID = target,
            source = {
                blockID = block.id,
                nodeID = nodeID,
                choiceID = choice.id,
                outcomeID = outcomeID,
            },
        }
        if not targetRows[target] then
            targetRows[target] = {
                target = target,
                outcomeIDs = {},
                weight = 0,
            }
            targets[#targets + 1] = target
        end
        targetRows[target].outcomeIDs[
            #targetRows[target].outcomeIDs + 1
        ] = outcomeID
        targetRows[target].weight = targetRows[target].weight
            + (tonumber(outcome.weight) or 1)
    end
    table.sort(targets)
    return outcomes, targets, targetRows
end

local function graphChoiceProjection(
    block,
    nodeID,
    choice,
    context,
    topic,
    revision
)
    local eligible, reason = Selector.IsChoiceEligible(
        block, nodeID, choice, context
    )
    local textPayload = dialoguePayload(
        block.textSource, choice.textKey, context
    )
    local outcomes, targets, targetRows = graphOutcomes(
        block, nodeID, choice
    )
    local safeReason = eligible and nil
        or tostring(choice.lockedReasonKey or reason
            or "choice_ineligible")
    local lockedTextValue
    if not eligible then
        lockedTextValue = resolveProjectionText(
            dialoguePayload(
                block.textSource,
                choice.lockedReasonKey or "",
                context
            )
        )
    end
    local choiceFrame = {
        schemaVersion = 1,
        kind = "semantic_click_frame",
        candidateID = table.concat({
            "conversation.choice", tostring(block.id),
            tostring(nodeID), tostring(choice.id),
        }, ":"),
        topic = topic,
        intent = "REQUEST",
        speechAct = "REQUEST",
        subject = "CONVERSATION_TOPIC",
        textKey = choice.textKey,
        textFallback = resolveProjectionText(textPayload),
        labelKey = choice.textKey,
        requestRevision = revision,
        extensions = {
            route = "conversation_choice",
            categoryID = block.category,
            blockID = block.id,
            nodeID = nodeID,
            choiceID = choice.id,
        },
    }
    local outcomeIDs = {}
    for _, outcome in ipairs(outcomes) do
        outcomeIDs[#outcomeIDs + 1] = outcome.id
    end
    return {
        eligible = eligible,
        enabled = eligible == true,
        safeReason = safeReason,
        textPayload = textPayload,
        targetRows = targetRows,
        choiceFrame = choiceFrame,
        row = {
            id = choice.id,
            textKey = choice.textKey,
            text = resolveProjectionText(textPayload),
            enabled = eligible == true,
            locked = eligible ~= true,
            lockedReasonKey = choice.lockedReasonKey,
            lockedReason = lockedTextValue or safeReason,
            outcomeIDs = outcomeIDs,
            nextNodeTargets = targets,
            outcomes = outcomes,
            frame = choiceFrame,
            source = {
                blockID = block.id,
                categoryID = block.category,
                nodeID = nodeID,
                choiceID = choice.id,
                textKey = choice.textKey,
            },
        },
    }
end

local function appendGraphEdges(
    edges,
    rootExits,
    availableTargets,
    lockedTargets,
    block,
    nodeID,
    choice,
    projection,
    currentNodeID
)
    for target, targetRow in pairs(projection.targetRows) do
        local isCurrent = nodeID == currentNodeID
        local edgeState
        if target == "$root" then
            edgeState = "root_exit"
        elseif isCurrent and projection.eligible then
            edgeState = "available"
            availableTargets[target] = true
        elseif isCurrent then
            edgeState = "locked"
            lockedTargets[target] = true
        else
            edgeState = "future"
        end
        local edge = {
            id = table.concat({
                "conversation.edge", block.id, nodeID,
                choice.id, target,
            }, ":"),
            fromNodeID = nodeID,
            toNodeID = target,
            targetKind = target == "$root"
                and "root_exit" or "conversation_node",
            kind = "conversation_choice",
            label = resolveProjectionText(projection.textPayload),
            choiceID = choice.id,
            enabled = projection.enabled,
            clickable = isCurrent and projection.enabled,
            state = edgeState,
            lockedReason = projection.safeReason,
            outcomeIDs = targetRow.outcomeIDs,
            weight = targetRow.weight,
            source = {
                blockID = block.id,
                categoryID = block.category,
                nodeID = nodeID,
                choiceID = choice.id,
                outcomeIDs = targetRow.outcomeIDs,
            },
            frame = projection.choiceFrame,
        }
        edges[#edges + 1] = edge
        if target == "$root" then rootExits[#rootExits + 1] = edge end
    end
end

local function graphNodeProjection(
    block,
    nodeID,
    context,
    topic,
    revision,
    currentNodeID,
    visited,
    availableTargets,
    lockedTargets,
    edges,
    rootExits
)
    local node = block.nodes[nodeID]
    local builtNode = Composer.BuildBlockNode(block, nodeID, context)
    local choiceRows = {}
    if type(node) == "table" then
        for _, choice in ipairs(node.choices or {}) do
            if type(choice) == "table"
                and tostring(choice.id or "") ~= ""
            then
                local projection = graphChoiceProjection(
                    block, nodeID, choice, context, topic, revision
                )
                choiceRows[#choiceRows + 1] = projection.row
                appendGraphEdges(
                    edges,
                    rootExits,
                    availableTargets,
                    lockedTargets,
                    block,
                    nodeID,
                    choice,
                    projection,
                    currentNodeID
                )
            end
        end
    end
    local npcText = builtNode and builtNode.npc
        and resolveProjectionText(builtNode.npc) or ""
    return {
        id = nodeID,
        title = nodeID,
        npcText = npcText,
        textKey = node and node.textKey or nil,
        state = "future",
        current = nodeID == currentNodeID,
        visited = containsID(visited, nodeID),
        choices = choiceRows,
        source = {
            blockID = block.id,
            categoryID = block.category,
            nodeID = nodeID,
            textKey = node and node.textKey or nil,
        },
    }
end

local function assignGraphNodeStates(
    nodes,
    currentNodeID,
    availableTargets,
    lockedTargets
)
    for _, node in ipairs(nodes) do
        if node.id == currentNodeID then
            node.state = "current"
        elseif node.visited then
            node.state = "visited"
        elseif availableTargets[node.id] then
            node.state = "available"
        elseif lockedTargets[node.id] then
            node.state = "locked"
        else
            node.state = "future"
        end
    end
end

-- Developer-only read projection of the complete selected authored block.
-- This deliberately does not replace BuildSemanticBlockProjection: the normal
-- player-facing surface must remain bounded to the current node.  The graph
-- is derived from the authoritative registry and live context on demand and
-- carries no state of its own.
function Composer.BuildSemanticConversationGraphProjection(view)
    local spec = view and view.spec or nil
    local context = spec and spec.context or nil
    local session = view and view.session or nil
    local blockID = context and context.activeConversationBlockID or nil
    local registry = PNC.Conversation and PNC.Conversation.Registry or Registry
    local block = blockID and registry
        and type(registry.GetBlock) == "function"
        and registry.GetBlock(blockID) or nil
    if not block or not session or type(block.nodes) ~= "table" then
        return nil
    end

    local currentNodeID = normalizeGraphNodeID(session.currentNodeID)
    if currentNodeID == "" or not block.nodes[currentNodeID] then
        return nil
    end

    local revision = graphRevision(view, session)
    local topic = graphTopic(block)
    local visited = session.semanticConversationVisitedNodes or {}
    local nodeIDs = {}
    for nodeID in pairs(block.nodes) do nodeIDs[#nodeIDs + 1] = nodeID end
    table.sort(nodeIDs)

    local nodes = {}
    local edges = {}
    local rootExits = {}
    local availableTargets = {}
    local lockedTargets = {}

    for _, nodeID in ipairs(nodeIDs) do
        nodes[#nodes + 1] = graphNodeProjection(
            block,
            nodeID,
            context,
            topic,
            revision,
            currentNodeID,
            visited,
            availableTargets,
            lockedTargets,
            edges,
            rootExits
        )
    end

    assignGraphNodeStates(
        nodes, currentNodeID, availableTargets, lockedTargets
    )
    table.sort(edges, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
    return {
        schema = "semantic_lab.graph.v1",
        schemaVersion = 1,
        graphKind = "conversation_block",
        graphID = "conversation_block:" .. tostring(block.id),
        title = tostring(block.category or block.id),
        blockID = block.id,
        categoryID = block.category,
        topic = topic,
        revision = revision,
        currentNodeID = currentNodeID,
        visitedNodeIDs = visited,
        entryNodeID = block.entryNode,
        source = sourceProjection(block.textSource),
        sourceIDs = {
            blockID = block.id,
            categoryID = block.category,
            ownerModID = block.ownerModID,
            textDomain = block.textSource and block.textSource.domain,
            textPathPattern = block.textSource
                and block.textSource.pathPattern,
        },
        nodes = nodes,
        edges = edges,
        rootExits = rootExits,
    }
end

return Composer

