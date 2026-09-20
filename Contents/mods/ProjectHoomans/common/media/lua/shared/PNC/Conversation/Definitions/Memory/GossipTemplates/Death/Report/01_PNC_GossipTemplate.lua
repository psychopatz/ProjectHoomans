PNC.Conversation.Memory.RegisterGossipTemplate({
    id = "gossip.death_report",
    code = 3001,
    event = "death",
    sentiment = "negative",
    tone = "somber",
    textKey = "death.report",
    arguments = {
        "subject",
    },
})
return true
