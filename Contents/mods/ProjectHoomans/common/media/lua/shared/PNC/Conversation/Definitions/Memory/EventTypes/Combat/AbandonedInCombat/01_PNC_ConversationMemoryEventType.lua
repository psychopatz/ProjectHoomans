local memory = PNC.Conversation.Memory

memory.Events.RegisterType({
    id = "abandoned_in_combat",
    code = 1102,
    sourceTypes = { "abandoned_in_combat" },
    salience = 235,
    longTerm = true,
    gossipEvent = "abandonment",
})

return true
