local H = PNC.Conversation.DefinitionHelpers
for _, audience in ipairs({ "neutral", "member", "special" }) do
    H.RegisterSimple("needs", audience, { choices = {
        H.ContinueChoice("supplies"),
        H.ContinueChoice("medical"),
    } })
end
return true
