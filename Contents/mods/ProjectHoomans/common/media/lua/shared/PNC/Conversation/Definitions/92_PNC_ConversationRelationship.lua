local H = PNC.Conversation.DefinitionHelpers
H.RegisterSimple("relationship", "special", {
    gates = {{
        type = "pnc:relationship", axis = "approval",
        operator = ">=", value = 20, reasonKey = "locked.approval",
    }},
    choices = {
        H.ContinueChoice("us", {
            { type = "pnc:relationship", approval = 2, familiarity = 2 },
        }),
    },
})
return true
