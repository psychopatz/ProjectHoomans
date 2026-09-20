local Memory = PNC.Conversation.Memory
local definitions = {
    { id = "gossip.corpse.relative.01", code = 3101, textKey = "corpse.relative.01" },
    { id = "gossip.corpse.relative.02", code = 3102, textKey = "corpse.relative.02" },
    { id = "gossip.corpse.relative.03", code = 3103, textKey = "corpse.relative.03" },
    { id = "gossip.corpse.relative.04", code = 3104, textKey = "corpse.relative.04" },
    { id = "gossip.corpse.relative.05", code = 3105, textKey = "corpse.relative.05" },
}

for index = 1, #definitions do
    local definition = definitions[index]
    definition.event = "corpse_seen_relative"
    definition.sentiment = "negative"
    definition.tone = "grief"
    definition.arguments = { "subject", "faction" }
    definition.weight = 10000
    Memory.RegisterGossipTemplate(definition)
end

local revengeDefinitions = {
    { id = "gossip.corpse.revenge.relative.01", code = 3126, textKey = "corpse.revenge.relative.01" },
    { id = "gossip.corpse.revenge.relative.02", code = 3127, textKey = "corpse.revenge.relative.02" },
    { id = "gossip.corpse.revenge.relative.03", code = 3128, textKey = "corpse.revenge.relative.03" },
    { id = "gossip.corpse.revenge.relative.04", code = 3129, textKey = "corpse.revenge.relative.04" },
    { id = "gossip.corpse.revenge.relative.05", code = 3130, textKey = "corpse.revenge.relative.05" },
    { id = "gossip.corpse.revenge.relative.06", code = 3131, textKey = "corpse.revenge.relative.06" },
    { id = "gossip.corpse.revenge.relative.07", code = 3132, textKey = "corpse.revenge.relative.07" },
    { id = "gossip.corpse.revenge.relative.08", code = 3133, textKey = "corpse.revenge.relative.08" },
}

for index = 1, #revengeDefinitions do
    local definition = revengeDefinitions[index]
    definition.event = "corpse_seen_revenge_relative"
    definition.sentiment = "negative"
    definition.tone = "revenge"
    definition.arguments = { "subject", "faction", "killer" }
    definition.weight = 10000
    Memory.RegisterGossipTemplate(definition)
end

return true
