-- A rescue is durable and shareable; its wording matches the rescue template.
local memory = PNC.Conversation.Memory

memory.Events.RegisterType({
    id = "saved_from_incapacitation",
    code = 1101,
    sourceTypes = { "saved_from_incapacitation" },
    salience = 245,
    longTerm = true,
    gossipEvent = "rescue",
})

return true
