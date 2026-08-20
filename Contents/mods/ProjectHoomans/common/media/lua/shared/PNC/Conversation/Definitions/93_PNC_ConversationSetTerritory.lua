local H = PNC.Conversation.DefinitionHelpers

H.RegisterSimple("set_territory", "member", {
    priority = 1000,
    gates = {
        { type = "pnc:audience", value = "member" },
        { type = "pnc:base_not_established",
            reasonKey = "locked.base_established" },
    },
    choices = {
        {
            id = "set_territory",
            textKey = "choice.set_territory",
            outcomes = {
                H.Outcome("claim", "response.set_territory", {
                    close = true,
                    effects = {{ type = "pnc:open_territory_claim" }},
                }),
            },
        },
    },
})

return true
