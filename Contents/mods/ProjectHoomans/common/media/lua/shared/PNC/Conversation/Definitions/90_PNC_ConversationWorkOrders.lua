local H = PNC.Conversation.DefinitionHelpers
H.RegisterSimple("work_orders", "member", { choices = {
    H.ContinueChoice("orders"),
    H.ContinueChoice("status"),
} })
return true
