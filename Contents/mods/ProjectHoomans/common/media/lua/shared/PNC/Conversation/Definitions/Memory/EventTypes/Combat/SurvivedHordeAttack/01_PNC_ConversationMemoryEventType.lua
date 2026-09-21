local memory = PNC.Conversation.Memory

memory.Events.RegisterType({
    id = "survived_horde_attack",
    code = 1104,
    sourceTypes = { "survived_horde_attack" },
    salience = 245,
    longTerm = true,
    gossipEvent = "horde_survival",
})

return true
