local Memory = PNC.Conversation.Memory
local definitions = {
    { id = "gossip.corpse.hostile.01", code = 3116, textKey = "corpse.hostile.01" },
    { id = "gossip.corpse.hostile.02", code = 3117, textKey = "corpse.hostile.02" },
    { id = "gossip.corpse.hostile.03", code = 3118, textKey = "corpse.hostile.03" },
    { id = "gossip.corpse.hostile.04", code = 3119, textKey = "corpse.hostile.04" },
    { id = "gossip.corpse.hostile.05", code = 3120, textKey = "corpse.hostile.05" },
}

for index = 1, #definitions do
    local definition = definitions[index]
    definition.event = "corpse_seen_hostile"
    definition.sentiment = "mixed"
    definition.tone = "bitter"
    definition.arguments = { "subject", "faction" }
    definition.weight = 10000
    Memory.RegisterGossipTemplate(definition)
end

return true
