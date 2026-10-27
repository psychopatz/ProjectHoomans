-- Explicit ownership boundary for categories whose meaning is selected by
-- semantic flows while ConversationBlocks retain authored data and effects.
--
-- This is intentionally a read-only ownership manifest. It lets the
-- composer, semantic projections, and the Semantic Lab agree that the
-- registry is only a bounded data/projection source.
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

Ownership.VERSION = 2
Ownership.MIGRATION_PHASE = "semantic_category_authority"
Ownership.AUTHORITY = "semantic_response_flow"
Ownership.REGISTRY_ROLE = "eligibility_gates_effects_projection"
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
        registryRole = Ownership.REGISTRY_ROLE,
        registryOwner = "conversation_registry_data",
        meaningAuthority = "semantic_response_flow",
        migrationPhase = Ownership.MIGRATION_PHASE,
        legacyRegistry = false,
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
