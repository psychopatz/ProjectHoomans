local H = PNC.Conversation.DefinitionHelpers
H.RegisterSimple("work_orders", "member", "work_orders/member/status", { choices = {
    H.ContinueChoice("orders"),
    H.ContinueChoice("status"),
} })
return true
