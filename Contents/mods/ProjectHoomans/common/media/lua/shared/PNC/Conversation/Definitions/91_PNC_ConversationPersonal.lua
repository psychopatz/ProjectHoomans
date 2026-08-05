local H = PNC.Conversation.DefinitionHelpers
H.RegisterSimple("personal", "special", {
    gates = {{
        type = "pnc:relationship", axis = "familiarity",
        operator = ">=", value = 10, reasonKey = "locked.familiarity",
    }},
    choices = {
        H.ContinueChoice("trust", {
            { type = "pnc:relationship", approval = 2, familiarity = 2 },
        }),
    },
})
return true
