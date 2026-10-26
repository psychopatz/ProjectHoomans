local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Internal = Composer.Internal
local TopicCatalog = Internal.TopicCatalog
local CategoryOwnership = Internal.CategoryOwnership

local function resolveProjectionText(value)
    if type(value) == "table" then
        local text = PsychopatzCore
            and PsychopatzCore.Conversation
            and PsychopatzCore.Conversation.Text
        if text and type(text.Resolve) == "function" then
            local ok, resolved = pcall(text.Resolve, value)
            if ok and resolved ~= nil then return tostring(resolved) end
        end
        return tostring(value.text or value.fallback or "")
    end
    return tostring(value or "")
end

local function semanticProjection(choice)
    local semantic = type(choice) == "table" and choice.semantic or nil
    if type(semantic) ~= "table" then return nil end
    local output = {}
    for _, key in ipairs({
        "route", "categoryID", "topic", "choiceID", "actionID", "groupID",
    }) do
        if semantic[key] ~= nil then output[key] = semantic[key] end
    end
    local ownership = CategoryOwnership
        and type(CategoryOwnership.Get) == "function"
        and CategoryOwnership.Get(semantic.categoryID) or nil
    if ownership then
        output.semanticOwner = ownership.semanticOwner
        output.legacyRegistry = ownership.legacyRegistry
        output.migrationPhase = ownership.migrationPhase
        output.authority = ownership.authority
    end
    return output
end

local function rootNodeFor(view)
    local spec = view and view.spec or nil
    local nodes = spec and spec.nodes or nil
    if type(nodes) ~= "table" then return nil, nil end
    -- Keep the semantic landing projection anchored to the production root.
    -- The live session enters authored blocks after the landing page, so its
    -- current node is not a stable root identity.
    -- BuildDefinition exposes the stable menu projection alongside the
    -- greeting entry. Prefer that identity so native and headless callers
    -- produce the same root frame IDs while the live session is elsewhere.
    for _, nodeID in ipairs({ "menu", "greeting" }) do
        local node = nodes[nodeID]
        if type(node) == "table" then return node, nodeID end
    end
    return nil, nil
end

-- Read-only semantic projection of the dynamic production root choices. The
-- source entries retain their existing action/next/close handlers; this
-- projection carries only bounded display and route metadata.
function Composer.BuildSemanticRootProjection(view)
    local node, nodeID = rootNodeFor(view)
    if type(node) ~= "table" then return nil end
    local choices = {}
    for _, entry in ipairs(node.choices or {}) do
        local semantic = semanticProjection(entry)
        if type(entry) == "table"
            and tostring(entry.id or "") ~= ""
            and semantic ~= nil
        then
            choices[#choices + 1] = {
                id = entry.id,
                textKey = entry.textKey,
                text = resolveProjectionText(entry.text),
                enabled = entry.enabled ~= false,
                tooltip = entry.tooltip,
                semantic = semantic,
            }
        end
    end
    return { nodeID = nodeID, choices = choices }
end

-- Resolve a semantic root frame back to the exact production choice entry.
-- This is deliberately fail-closed and never executes a projected function.
function Composer.ResolveSemanticRootChoice(view, frame)
    local extensions = type(frame) == "table"
        and type(frame.extensions) == "table" and frame.extensions or nil
    if not extensions or extensions.origin ~= "conversation_root" then
        return nil, "conversation_root_origin_invalid"
    end
    local node, nodeID = rootNodeFor(view)
    if not node or tostring(extensions.rootNodeID or "") ~= nodeID then
        return nil, "conversation_root_stale"
    end
    local requestedID = tostring(
        extensions.rootChoiceID or extensions.actionID
            or extensions.choiceID or ""
    )
    if requestedID == "" then return nil, "conversation_root_choice_invalid" end
    for _, entry in ipairs(node.choices or {}) do
        local semantic = semanticProjection(entry)
        if type(entry) == "table" and tostring(entry.id or "") == requestedID
            and type(semantic) == "table"
            and semantic.route == extensions.route
            and (extensions.categoryID == nil
                or semantic.categoryID == extensions.categoryID)
            and (extensions.actionID == nil
                or semantic.actionID == extensions.actionID)
        then
            if entry.enabled == false then
                return nil, "conversation_root_choice_disabled"
            end
            return entry
        end
    end
    return nil, "conversation_root_choice_unknown"
end

-- Read-only semantic projection of the same authored block/node that the
-- native composer currently presents. The semantic suggestion layer consumes
-- this projection; it does not maintain a second block or choice state.
function Composer.BuildSemanticBlockProjection(view)
    local spec = view and view.spec or nil
    local context = spec and spec.context or nil
    local session = view and view.session or nil
    local blockID = context and context.activeConversationBlockID or nil
    local registry = PNC.Conversation and PNC.Conversation.Registry
        or Registry
    local block = blockID
        and registry
        and type(registry.GetBlock) == "function"
        and registry.GetBlock(blockID) or nil
    if not block or not session then return nil end
    local nodeID = tostring(session.currentNodeID or "")
    if string.sub(nodeID, 1, 6) == "block:" then
        nodeID = string.sub(nodeID, 7)
    end
    if nodeID == "" or type(block.nodes) ~= "table"
        or type(block.nodes[nodeID]) ~= "table"
    then
        return nil
    end
    local builtNode = spec.nodes
        and spec.nodes["block:" .. nodeID]
        or Composer.BuildBlockNode(block, nodeID, context)
    if type(builtNode) ~= "table" then return nil end
    local topicCatalog = PNC.Semantics and PNC.Semantics.TopicCatalog
        or TopicCatalog
    local authoredTopic = topicCatalog
        and type(topicCatalog.AuthoredTopic) == "function"
        and topicCatalog.AuthoredTopic(block) or block.topic
    local ownership = CategoryOwnership
        and type(CategoryOwnership.ForBlock) == "function"
        and CategoryOwnership.ForBlock(block) or nil
    local choices = {}
    for _, entry in ipairs(builtNode.choices or {}) do
        if type(entry) == "table" and tostring(entry.id or "") ~= "" then
            local authoredChoice
            for _, candidate in ipairs(
                block.nodes[nodeID].choices or {}
            ) do
                if type(candidate) == "table"
                    and candidate.id == entry.id
                then
                    authoredChoice = candidate
                    break
                end
            end
            choices[#choices + 1] = {
                id = entry.id,
                textKey = entry.textKey,
                text = resolveProjectionText(entry.text),
                enabled = entry.enabled == true,
                lockedReasonKey = authoredChoice
                    and authoredChoice.lockedReasonKey or nil,
            }
        end
    end
    return {
        categoryID = block.category,
        blockID = block.id,
        topic = authoredTopic,
        semanticOwner = ownership and ownership.semanticOwner or nil,
        ownership = ownership,
        nodeID = nodeID,
        npcText = resolveProjectionText(builtNode.npc),
        choices = choices,
    }
end

Internal.ResolveProjectionText = resolveProjectionText

return Composer

