-- Authored conversation-block projection.

local Block = {}
local Payload = require "worker/Conversation_Payload"

function Block.project(view)
    local composer = PNC.Conversation and PNC.Conversation.Composer
    if composer and type(composer.BuildSemanticBlockProjection) == "function" then
        local projection = composer.BuildSemanticBlockProjection(view)
        if projection then return projection end
    end
    local spec = view and view.spec or nil
    local root = spec and spec.context or nil
    local nodes = spec and spec.nodes or nil
    local blockID = root and root.activeConversationBlockID or nil
    if not blockID or type(nodes) ~= "table" then return nil end
    local nodeID = view.session and view.session.currentNodeID or nil
    if not nodeID or string.sub(tostring(nodeID), 1, 6) == "block:" then
        nodeID = string.sub(tostring(nodeID or ""), 7)
    end
    if nodeID == "" then return nil end
    local node = nodes["block:" .. tostring(nodeID)]
    if type(node) ~= "table" then return nil end
    local block = PNC.Conversation and PNC.Conversation.Registry
        and PNC.Conversation.Registry.GetBlock
        and PNC.Conversation.Registry.GetBlock(blockID) or nil
    local ownership = PNC.Semantics
        and PNC.Semantics.ConversationCategoryOwnership
    if type(ownership) ~= "table" then
        local ok, loaded = pcall(require,
            "PNC/Semantics/PNC_SemanticConversationCategoryOwnership")
        ownership = PNC.Semantics
            and PNC.Semantics.ConversationCategoryOwnership
        if type(ownership) ~= "table" and ok and type(loaded) == "table" then
            ownership = loaded
        end
    end
    local categoryOwnership = ownership
        and type(ownership.ForBlock) == "function"
        and ownership.ForBlock(block) or nil
    local topic = block and block.topic or nil
    if not topic and block
        and PNC.Semantics and PNC.Semantics.TopicCatalog
        and type(PNC.Semantics.TopicCatalog.AuthoredTopic) == "function"
    then
        topic = PNC.Semantics.TopicCatalog.AuthoredTopic(block)
    end
    if not topic and block and PNC.Semantics
        and PNC.Semantics.TopicCatalog
        and type(PNC.Semantics.TopicCatalog.AUTHORED_CATEGORY_TOPICS) == "table"
    then
        topic = PNC.Semantics.TopicCatalog.AUTHORED_CATEGORY_TOPICS[
            block.category
        ]
    end
    local choices = {}
    for _, choice in ipairs(node.choices or {}) do
        if type(choice) == "table" then
            choices[#choices + 1] = {
                id = choice.id,
                textKey = choice.textKey,
                text = Payload.resolve(choice.text),
                enabled = choice.enabled == true,
                lockedReasonKey = choice.lockedReasonKey,
            }
        end
    end
    return {
        categoryID = block and block.category or root.categoryID,
        blockID = blockID,
        nodeID = nodeID,
        topic = topic or root.conversationTopic,
        semanticOwner = categoryOwnership
            and categoryOwnership.semanticOwner or nil,
        ownership = categoryOwnership,
        npcText = Payload.resolve(node.npc),
        choices = choices,
    }
end

return Block

