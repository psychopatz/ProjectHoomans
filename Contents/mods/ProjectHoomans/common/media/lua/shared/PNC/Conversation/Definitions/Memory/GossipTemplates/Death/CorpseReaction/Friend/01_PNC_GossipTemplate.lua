local Memory = PNC.Conversation.Memory
local definitions = {
    { id = "gossip.corpse.friend.01", code = 3106, textKey = "corpse.friend.01" },
    { id = "gossip.corpse.friend.02", code = 3107, textKey = "corpse.friend.02" },
    { id = "gossip.corpse.friend.03", code = 3108, textKey = "corpse.friend.03" },
    { id = "gossip.corpse.friend.04", code = 3109, textKey = "corpse.friend.04" },
    { id = "gossip.corpse.friend.05", code = 3110, textKey = "corpse.friend.05" },
}

for index = 1, #definitions do
    local definition = definitions[index]
    definition.event = "corpse_seen_friend"
    definition.sentiment = "negative"
    definition.tone = "grief"
    definition.arguments = { "subject", "faction" }
    definition.weight = 10000
    Memory.RegisterGossipTemplate(definition)
end

local revengeDefinitions = {
    { id = "gossip.corpse.revenge.friend.01", code = 3134, textKey = "corpse.revenge.friend.01" },
    { id = "gossip.corpse.revenge.friend.02", code = 3135, textKey = "corpse.revenge.friend.02" },
    { id = "gossip.corpse.revenge.friend.03", code = 3136, textKey = "corpse.revenge.friend.03" },
    { id = "gossip.corpse.revenge.friend.04", code = 3137, textKey = "corpse.revenge.friend.04" },
    { id = "gossip.corpse.revenge.friend.05", code = 3138, textKey = "corpse.revenge.friend.05" },
    { id = "gossip.corpse.revenge.friend.06", code = 3139, textKey = "corpse.revenge.friend.06" },
    { id = "gossip.corpse.revenge.friend.07", code = 3140, textKey = "corpse.revenge.friend.07" },
    { id = "gossip.corpse.revenge.friend.08", code = 3141, textKey = "corpse.revenge.friend.08" },
}

for index = 1, #revengeDefinitions do
    local definition = revengeDefinitions[index]
    definition.event = "corpse_seen_revenge_friend"
    definition.sentiment = "negative"
    definition.tone = "revenge"
    definition.arguments = { "subject", "faction", "killer" }
    definition.weight = 10000
    Memory.RegisterGossipTemplate(definition)
end

return true
