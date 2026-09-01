local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
T.load("ProjectHoomans", "shared",
    "PNC/Conversation/PNC_ConversationToolReplies.lua")

local Replies = PNC.Conversation.ToolReplies
local context = {
    request_id = "reply-catalog-1",
    npc_name = "Harley",
}

local admire = Replies.Build({
    {
        id = "admire-1",
        name = "social_react",
        accepted = true,
        authoritative = true,
        reason = "applied",
        reaction = "admire",
    },
}, context)
T.truthy(admire and admire ~= "I hear you.",
    "accepted admiration uses a dedicated contextual reply")

local cooldown = Replies.Build({
    {
        id = "cooldown-1",
        name = "social_react",
        accepted = false,
        authoritative = true,
        reason = "positive_cooldown_active",
        reaction = "praise",
    },
}, context)
T.truthy(cooldown and (
    string.find(cooldown, "today", 1, true)
        or string.find(cooldown, "tomorrow", 1, true)
),
    "cooldown rejection gets a specific reply")

local queued = Replies.Build({
    {
        id = "queued-1",
        name = "social_react",
        accepted = true,
        authoritative = false,
        reason = "network_queued",
        reaction = "flirt",
    },
}, context)
T.truthy(queued and queued ~= admire,
    "queued actions use a separate non-committal reply")

local sexualBoundary = Replies.Build({
    {
        id = "sexual-boundary-1",
        name = "social_react",
        accepted = false,
        authoritative = true,
        reason = "relationship_gate",
        reaction = "flirt",
        subtype = "sexual_advance",
    },
}, context)
T.truthy(sexualBoundary and (
    string.find(sexualBoundary, "happening", 1, true)
        or string.find(sexualBoundary, "talk to me", 1, true)
        or string.find(sexualBoundary, "fast", 1, true)
), "sexual advances get a direct boundary reply")

local hostile = Replies.Build({
    {
        id = "hostile-1",
        name = "social_react",
        accepted = true,
        authoritative = true,
        reason = "applied",
        reaction = "insult",
        subtype = "hostile_abuse",
    },
}, context)
T.truthy(hostile and (
    string.find(hostile, "mouth", 1, true)
        or string.find(hostile, "habit", 1, true)
        or string.find(hostile, "happens", 1, true)
), "hostile abuse gets a boundary reply")

local nameReply = Replies.Build({
    {
        id = "name-1",
        name = "ask_name",
        accepted = true,
        reason = "dispatched",
    },
}, context)
T.truthy(nameReply and string.find(nameReply, "Harley", 1, true),
    "name tool reply uses the authoritative NPC name")

local orderReply = Replies.Build({
    {
        id = "order-1",
        name = "order_follow",
        commandID = "follow",
        accepted = true,
        reason = "submitted",
    },
}, context)
T.truthy(orderReply and orderReply ~= "All right.",
    "order tools use dedicated contextual replies")

local campReply = Replies.Build({
    {
        id = "order-camp-1",
        name = "order_camp",
        commandID = "camp",
        accepted = true,
        reason = "submitted",
    },
}, context)
T.truthy(campReply and (
    string.find(campReply, "camp", 1, true)
        or string.find(campReply, "settle", 1, true)
        or string.find(campReply, "needs", 1, true)
), "camp order uses a dedicated contextual reply")

local secondAdmire = Replies.Build({
    {
        id = "admire-2",
        name = "social_react",
        accepted = true,
        authoritative = true,
        reason = "applied",
        reaction = "admire",
    },
}, context)
T.truthy(secondAdmire ~= admire,
    "successive replies avoid immediately repeating a variant")

T.finish("pnc_llm_tool_reply_catalog_smoke")
