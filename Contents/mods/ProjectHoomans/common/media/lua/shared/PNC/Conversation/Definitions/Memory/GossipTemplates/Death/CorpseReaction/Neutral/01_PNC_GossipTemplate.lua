local Memory = PNC.Conversation.Memory
local definitions = {
    { id = "gossip.corpse.neutral.01", code = 3121, textKey = "corpse.neutral.01" },
    { id = "gossip.corpse.neutral.02", code = 3122, textKey = "corpse.neutral.02" },
    { id = "gossip.corpse.neutral.03", code = 3123, textKey = "corpse.neutral.03" },
    { id = "gossip.corpse.neutral.04", code = 3124, textKey = "corpse.neutral.04" },
    { id = "gossip.corpse.neutral.05", code = 3125, textKey = "corpse.neutral.05" },
}

for index = 1, #definitions do
    local definition = definitions[index]
    definition.event = "corpse_seen_neutral"
    definition.sentiment = "neutral"
    definition.tone = "somber"
    definition.arguments = { "subject", "faction" }
    definition.weight = 10000
    Memory.RegisterGossipTemplate(definition)
end

return true
