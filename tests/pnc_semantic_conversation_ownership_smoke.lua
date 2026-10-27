local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticTopicCatalog.lua"
)
local Ownership = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticConversationCategoryOwnership.lua"
)

local expected = {
    ["projecthoomans:wellbeing"] = "wellbeing",
    ["projecthoomans:small_talk"] = "small_talk",
    ["projecthoomans:ask_about"] = "ask_about",
}

for categoryID, topic in pairs(expected) do
    local metadata = Ownership.Get(categoryID)
    T.truthy(metadata, categoryID .. " has an ownership record")
    T.equal(metadata.topic, topic, categoryID .. " reuses the authored topic")
    T.equal(
        metadata.semanticOwner,
        "projecthoomans.semantic." .. topic,
        categoryID .. " has a stable semantic owner"
    )
    T.equal(
        metadata.authority,
        "semantic_response_flow",
        categoryID .. " reports semantic meaning authority"
    )
    T.equal(
        metadata.registryRole,
        "eligibility_gates_effects",
        categoryID .. " retains registry gates/effects ownership"
    )
    T.equal(
        metadata.registryOwner,
        "conversation_registry",
        categoryID .. " records the legacy registry data owner"
    )
    T.equal(
        metadata.migrationPhase,
        "semantic_category_authority",
        categoryID .. " is explicitly marked as semantic-owned"
    )
end

local blockMetadata = Ownership.ForBlock({
    id = "projecthoomans:wellbeing_basic_neutral",
    category = "projecthoomans:wellbeing",
})
T.equal(
    blockMetadata.blockID,
    "projecthoomans:wellbeing_basic_neutral",
    "block ownership keeps the exact legacy block identity"
)
T.truthy(
    Ownership.IsSemanticOwned("projecthoomans:ask_about"),
    "Ask About is in the first semantic ownership slice"
)
T.falsy(
    Ownership.IsSemanticOwned("projecthoomans:trade"),
    "unmigrated categories remain outside the first ownership slice"
)
local valid, reason = Ownership.Validate()
T.truthy(valid, reason)

T.finish("pnc_semantic_conversation_ownership_smoke")
