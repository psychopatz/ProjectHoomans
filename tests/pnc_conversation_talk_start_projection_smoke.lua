local T = require "tests/support/test"

T.addPackagePaths()

PNC = {
    Const = { ORDER_FOLLOW = "follow" },
    Conversation = {},
}

local TalkStart = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_ConversationTalkStart.lua"
)

local function entry(fields)
    fields = fields or {}
    fields.id = fields.id or "npc-talk-start"
    fields.snapshot = fields.snapshot or {}
    fields.record = fields.record or {}
    return fields
end

local neutral = TalkStart.Project(entry({
    tacticalClass = "neutral",
    relationship = { category = "FirstMeet" },
}), nil, { source = "smoke" })
T.equal(neutral.schema, "semantic.talk.start.projection.v1",
    "projection schema")
T.equal(neutral.targetType, "neutral", "neutral target type")
T.equal(neutral.tacticalClass, "neutral", "neutral tactical class")
T.equal(neutral.route, "full_conversation", "neutral route")
T.equal(neutral.audience, "neutral", "neutral audience")
T.equal(neutral.opening.nodeID, "greeting", "shared opening node")

local follower = TalkStart.Project(entry({
    tacticalClass = "colonist",
    recruited = true,
    orderKind = "follow",
    orderSpec = { kind = "follow" },
}), nil, { source = "smoke" })
T.equal(follower.targetType, "follower", "follower is derived")
T.equal(follower.tacticalClass, "colonist", "follower keeps tactical class")
T.equal(follower.ownership.orderKind, "follow", "follow fact is projected")

local hostile = TalkStart.Project(entry({
    tacticalClass = "hostile",
    hostility = { attackPlayers = true },
}), nil, { source = "smoke" })
T.equal(hostile.audience, "hostile", "hostile audience")
T.equal(hostile.route, "hostile_full_conversation",
    "headless hostile fallback route")
T.falsy(hostile.hostileInlineAvailable,
    "headless projection does not fake inline support")

PNC.Conversation.InlineChat = {}
local unavailableInline = TalkStart.Project(entry({
    tacticalClass = "hostile",
    hostility = { attackPlayers = true },
}), nil, { source = "smoke" })
T.equal(unavailableInline.route, "hostile_full_conversation",
    "unwired inline hostile fallback route")
T.equal(unavailableInline.hostileInlineReason, "inline_route_unavailable",
    "unwired inline route reason is retained")

PNC.Conversation.InlineChat.OpenForTarget = function() return true end
local availableInline = TalkStart.Project(entry({
    tacticalClass = "hostile",
    hostility = { attackPlayers = true },
}), nil, { source = "smoke" })
T.equal(availableInline.route, "hostile_inline",
    "semantic-first inline chat uses inline route even without PBrainZ")
T.truthy(availableInline.hostileInlineAvailable,
    "semantic-first inline chat reports inline support")

local dead = TalkStart.Project(entry({
    tacticalClass = "neutral",
    alive = false,
}), nil, { source = "smoke" })
T.equal(dead.route, "unavailable", "dead target route")
T.equal(dead.availability.reason, "npc_unavailable",
    "dead target reason")

T.finish("pnc_conversation_talk_start_projection_smoke")
