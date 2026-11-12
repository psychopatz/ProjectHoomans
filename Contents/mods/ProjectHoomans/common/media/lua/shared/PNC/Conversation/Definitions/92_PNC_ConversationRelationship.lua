local H = PNC.Conversation.DefinitionHelpers
H.RegisterSimple("relationship", "special", "social/relationship/special/affinity", {
    textOwner = "PsychopatzCore",
    gates = {{
        type = "pnc:relationship", axis = "approval",
        operator = ">=", value = 20,
        reasonKey = "UI_PsychopatzConversation_Locked_Approval",
    }},
    choices = {
        H.ContinueChoice("us", {
            { type = "pnc:relationship", approval = 2, familiarity = 2 },
        }),
    },
})
return true
