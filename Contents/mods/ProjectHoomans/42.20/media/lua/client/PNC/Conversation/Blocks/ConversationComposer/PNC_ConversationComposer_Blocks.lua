local Conversation = PNC.Conversation
local Composer = Conversation.Composer
local Selector = Conversation.Selector
local Internal = Composer.Internal

local dialoguePayload = Internal.DialoguePayload
local ensureBlockText = Internal.EnsureBlockText
local selectedTextKey = Internal.SelectedTextKey

local TopicCatalog = PNC.Semantics and PNC.Semantics.TopicCatalog
if type(TopicCatalog) ~= "table" then
    pcall(require, "PNC/Semantics/PNC_SemanticTopicCatalog")
    TopicCatalog = PNC.Semantics and PNC.Semantics.TopicCatalog
end

local function syncSemanticTopic(spec, topic)
    if not topic or type(spec) ~= "table" then return false end
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local view = conversation and conversation.instance or nil
    local viewSpec = view and view.spec or nil
    if not view or not viewSpec
        or tostring(viewSpec.npcID or "") ~= tostring(spec.npcID or "")
    then
        return false, "conversation_unavailable"
    end
    local state = view.session and view.session.semanticDialogueState or nil
    if not state or type(state.SetTopic) ~= "function" then
        return false, "semantic_state_unavailable"
    end
    return state:SetTopic(topic)
end

local function lockedText(block, choice, reason, context)
    local key = choice.lockedReasonKey or reason
    if not key then
        return dialoguePayload(block.textSource, choice.textKey, context)
    end
    local text = PsychopatzCore.Conversation.Text
    local label = text.Resolve(dialoguePayload(
        block.textSource, choice.textKey, context
    ))
    local explanation = text.Resolve(dialoguePayload(
        block.textSource, key, context
    ))
    return { text = label .. " (" .. explanation .. ")" }
end

function Composer.BuildBlockNode(block, nodeID, context)
    local node = block.nodes[nodeID]
    if not node then return nil end
    local choices = {}
    for _, choice in ipairs(node.choices or {}) do
        local passed, reason = Selector.IsChoiceEligible(
            block, nodeID, choice, context
        )
        local mode = choice.lockedMode or "hidden"
        if passed or mode == "disabled" then
            local selectedChoice = choice
            choices[#choices + 1] = {
                id = selectedChoice.id,
                textKey = selectedChoice.textKey,
                text = passed
                    and dialoguePayload(
                        block.textSource,
                        selectedChoice.textKey,
                        context
                    )
                    or lockedText(block, selectedChoice, reason, context),
                enabled = passed,
                lockedReasonKey = selectedChoice.lockedReasonKey,
                action = passed and function()
                    Composer.RequestChoice(
                        context.npcID,
                        block.id,
                        nodeID,
                        selectedChoice.id
                    )
                end or nil,
            }
        end
    end
    return {
        npc = dialoguePayload(
            block.textSource,
            selectedTextKey(block, nodeID, node, context),
            context
        ),
        choices = choices,
    }
end

function Composer.AttachBlock(spec, block, context)
    local valid, errors = ensureBlockText(block)
    if not valid then return false, errors end
    spec.context.activeConversationBlockID = block.id
    local topic = TopicCatalog
        and type(TopicCatalog.AuthoredTopic) == "function"
        and TopicCatalog.AuthoredTopic(block) or nil
    if topic then
        -- Keep the authored topic in both projections. The presentation
        -- context feeds the provider payload; the block context feeds local
        -- semantic input after a menu-selected block is attached.
        spec.context.conversationTopic = topic
        if type(context) == "table" then
            context.conversationTopic = topic
        end
        syncSemanticTopic(spec, topic)
    end
    for nodeID in pairs(block.nodes) do
        spec.nodes["block:" .. nodeID] = Composer.BuildBlockNode(
            block, nodeID, context
        )
    end
    return true, "block:" .. block.entryNode
end

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
    return output
end

local function rootNodeFor(view)
    local spec = view and view.spec or nil
    local session = view and view.session or nil
    local nodeID = tostring(session and session.currentNodeID or "")
    if nodeID ~= "greeting" and nodeID ~= "menu" then return nil, nil end
    local node = spec and spec.nodes and spec.nodes[nodeID] or nil
    return node, nodeID
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
        nodeID = nodeID,
        npcText = resolveProjectionText(builtNode.npc),
        choices = choices,
    }
end


return Composer
