local memory = PNC.Conversation.Memory

memory.Events.RegisterType({
    id = "protected_from_attacker",
    code = 1103,
    sourceTypes = { "protected_from_attacker" },
    salience = 215,
    longTerm = true,
    gossipEvent = "protection",
})

return true
