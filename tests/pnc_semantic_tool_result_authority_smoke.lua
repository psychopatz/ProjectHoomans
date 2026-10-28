local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticToolResultRealization.lua")

local Realization = PNC.Semantics.ToolResultRealization
local Catalog = PNC.Semantics.ResponseCatalog

T.falsy(
    package.loaded["PNC/Conversation/PNC_ConversationToolReplyCatalog"],
    "semantic tool-result realization does not load the retired wording table"
)
T.falsy(PNC.Conversation and PNC.Conversation.ToolReplies,
    "retired Conversation.ToolReplies namespace is not recreated")

local social = Realization.Resolve({
    {
        id = "p5-social-1",
        name = "social_react",
        accepted = true,
        authoritative = true,
        reason = "applied",
        reaction = "admire",
    },
}, { request_id = "p5-1", npc_name = "Harley" })
T.truthy(social and social.semanticOwned,
    "social tool-result speech is marked semantic-owned")
T.equal(social.selectionSource, "semantic_response_catalog",
    "social tool-result speech selects through the semantic catalog")
T.equal(social.contentOwner,
    "projecthoomans.dialogue_content.tool_replies",
    "social tool-result speech exposes its canonical content owner")
T.equal(social.poolID, "semantic.tool_reply.social.accepted.admire",
    "social tool-result speech maps result facts to the explicit semantic pool")
T.truthy(social.responsePlan,
    "social tool-result speech carries the selected response plan")
T.falsy(string.find(social.text or "", "LEGACY SHOULD NOT BE USED", 1, true),
    "substituted legacy tool-result speech prose cannot change the semantic result")

local cooldown = Realization.Resolve({
    {
        id = "p5-social-2",
        name = "social_react",
        accepted = false,
        authoritative = true,
        reason = "positive_cooldown_active",
        reaction = "praise",
    },
}, { request_id = "p5-2", npc_name = "Harley" })
T.equal(cooldown.poolID,
    "semantic.tool_reply.social.rejected.positive_cooldown_active",
    "rejection reason selects the explicit semantic boundary pool")

local named = Realization.Resolve({
    { id = "p5-name", name = "ask_name", accepted = true },
}, { request_id = "p5-3", npc_name = "Harley" })
T.equal(named.poolID, "semantic.tool_reply.ask_name.named",
    "ask-name uses the semantic identity response pool")
T.truthy(string.find(named.text or "", "Harley", 1, true),
    "ask-name keeps the authoritative NPC identity argument")

local order = Realization.Resolve({
    {
        id = "p5-order",
        name = "order_camp",
        commandID = "camp",
        accepted = true,
    },
}, { request_id = "p5-4", npc_name = "Harley" })
T.equal(order.poolID, "semantic.tool_reply.order.camp",
    "companion order uses the semantic command-result pool")
T.truthy(order.text and string.find(order.text, "camp", 1, true),
    "camp acknowledgement preserves the accepted wording family")

T.truthy(Catalog.Get("semantic.tool_reply.social.accepted.admire"),
    "tool-result speech pools are registered in the production ResponseCatalog")
T.finish("pnc_semantic_tool_result_authority_smoke")
