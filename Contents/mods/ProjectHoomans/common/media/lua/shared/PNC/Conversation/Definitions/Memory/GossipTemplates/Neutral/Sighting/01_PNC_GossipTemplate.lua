PNC.Conversation.Memory.RegisterGossipTemplate({
    id = "gossip.neutral_sighting",
    code = 4001,
    event = "sighting",
    sentiment = "neutral",
    tone = "report",
    textKey = "neutral.sighting",
    arguments = {
        "subject",
        "place",
    },
})
return true
