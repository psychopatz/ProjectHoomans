local Memory = PNC.Conversation.Memory
local definitions = {
    { id = "gossip.corpse.comrade.01", code = 3111, textKey = "corpse.comrade.01" },
    { id = "gossip.corpse.comrade.02", code = 3112, textKey = "corpse.comrade.02" },
    { id = "gossip.corpse.comrade.03", code = 3113, textKey = "corpse.comrade.03" },
    { id = "gossip.corpse.comrade.04", code = 3114, textKey = "corpse.comrade.04" },
    { id = "gossip.corpse.comrade.05", code = 3115, textKey = "corpse.comrade.05" },
}

for index = 1, #definitions do
    local definition = definitions[index]
    definition.event = "corpse_seen_comrade"
    definition.sentiment = "negative"
    definition.tone = "somber"
    definition.arguments = { "subject", "faction" }
    definition.weight = 10000
    Memory.RegisterGossipTemplate(definition)
end

local revengeDefinitions = {
    { id = "gossip.corpse.revenge.comrade.01", code = 3142, textKey = "corpse.revenge.comrade.01" },
    { id = "gossip.corpse.revenge.comrade.02", code = 3143, textKey = "corpse.revenge.comrade.02" },
    { id = "gossip.corpse.revenge.comrade.03", code = 3144, textKey = "corpse.revenge.comrade.03" },
    { id = "gossip.corpse.revenge.comrade.04", code = 3145, textKey = "corpse.revenge.comrade.04" },
    { id = "gossip.corpse.revenge.comrade.05", code = 3146, textKey = "corpse.revenge.comrade.05" },
    { id = "gossip.corpse.revenge.comrade.06", code = 3147, textKey = "corpse.revenge.comrade.06" },
    { id = "gossip.corpse.revenge.comrade.07", code = 3148, textKey = "corpse.revenge.comrade.07" },
    { id = "gossip.corpse.revenge.comrade.08", code = 3149, textKey = "corpse.revenge.comrade.08" },
}

for index = 1, #revengeDefinitions do
    local definition = revengeDefinitions[index]
    definition.event = "corpse_seen_revenge_comrade"
    definition.sentiment = "negative"
    definition.tone = "revenge"
    definition.arguments = { "subject", "faction", "killer" }
    definition.weight = 10000
    Memory.RegisterGossipTemplate(definition)
end

return true
