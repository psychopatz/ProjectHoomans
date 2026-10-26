-- Explicit ownership boundary for categories that are still authored by the
-- legacy conversation registry but are already consumed by semantic flows.
--
-- This is intentionally a read-only compatibility manifest. It lets the
-- composer, semantic projections, and the Semantic Lab agree on ownership
-- before any legacy registration is removed.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Ownership = PNC.Semantics.ConversationCategoryOwnership or {}
PNC.Semantics.ConversationCategoryOwnership = Ownership

local TopicCatalog = PNC.Semantics.TopicCatalog
if type(TopicCatalog) ~= "table" then
    local ok, loaded = pcall(require,
        "PNC/Semantics/PNC_SemanticTopicCatalog")
    TopicCatalog = PNC.Semantics.TopicCatalog
    if type(TopicCatalog) ~= "table" and ok and type(loaded) == "table" then
        TopicCatalog = loaded
    end
end

Ownership.VERSION = 1
Ownership.MIGRATION_PHASE = "legacy_registry_projection"
Ownership.AUTHORITY = "conversation_registry"
Ownership.CATEGORY_IDS = {
    "projecthoomans:wellbeing",
    "projecthoomans:small_talk",
    "projecthoomans:ask_about",
}

local semanticCategories = {}
for _, categoryID in ipairs(Ownership.CATEGORY_IDS) do
    semanticCategories[categoryID] = true
end

local function authoredTopic(categoryID)
    if type(TopicCatalog) ~= "table"
        or type(TopicCatalog.AuthoredTopic) ~= "function"
    then
        return nil
    end
    return TopicCatalog.AuthoredTopic(categoryID)
end

local function copyMetadata(categoryID, blockID)
    local topic = authoredTopic(categoryID)
    if type(topic) ~= "string" or topic == "" then
        return nil, "category_topic_missing"
    end
    return {
        categoryID = categoryID,
        blockID = blockID,
        topic = topic,
        semanticOwner = "projecthoomans.semantic." .. topic,
        authority = Ownership.AUTHORITY,
        migrationPhase = Ownership.MIGRATION_PHASE,
        legacyRegistry = true,
    }
end

function Ownership.Get(categoryID)
    categoryID = tostring(categoryID or "")
    if not semanticCategories[categoryID] then return nil end
    return copyMetadata(categoryID)
end

function Ownership.ForBlock(block)
    if type(block) ~= "table" then return nil end
    local metadata = Ownership.Get(block.category)
    if not metadata then return nil end
    metadata.blockID = block.id
    return metadata
end

function Ownership.IsSemanticOwned(categoryID)
    return semanticCategories[tostring(categoryID or "")] == true
end

function Ownership.Validate()
    for _, categoryID in ipairs(Ownership.CATEGORY_IDS) do
        local metadata, reason = Ownership.Get(categoryID)
        if type(metadata) ~= "table" then
            return false, tostring(categoryID) .. ":" .. tostring(reason)
        end
    end
    return true
end

local valid, reason = Ownership.Validate()
if not valid then
    error("semantic conversation ownership manifest is invalid: "
        .. tostring(reason))
end

return Ownership
