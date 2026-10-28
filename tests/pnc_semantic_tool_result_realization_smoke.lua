local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
T.load("ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticToolResultRealization.lua")

local Realization = PNC.Semantics.ToolResultRealization
local context = {
    request_id = "reply-catalog-1",
    npc_name = "Harley",
}

local admire = Realization.Text({
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

local cooldown = Realization.Text({
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

local queued = Realization.Text({
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

local sexualBoundary = Realization.Text({
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

local hostile = Realization.Text({
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

local nameReply = Realization.Text({
    {
        id = "name-1",
        name = "ask_name",
        accepted = true,
        reason = "dispatched",
    },
}, context)
T.truthy(nameReply and string.find(nameReply, "Harley", 1, true),
    "name tool reply uses the authoritative NPC name")

local orderReply = Realization.Text({
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

local campReply = Realization.Text({
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

local secondAdmire = Realization.Text({
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

Realization.Reset()
for index = 1, 300 do
    Realization.Text({
        {
            id = "bounded-" .. tostring(index),
            name = "social_react",
            accepted = true,
            authoritative = true,
            reason = "applied",
            reaction = "admire",
            subtype = "bounded_" .. tostring(index),
        },
    }, context)
end
T.equal(#Realization.lastVariantOrder, Realization.MAX_LAST_VARIANTS,
    "tool-result realization anti-repeat state remains bounded")

T.finish("pnc_semantic_tool_result_realization_smoke")
