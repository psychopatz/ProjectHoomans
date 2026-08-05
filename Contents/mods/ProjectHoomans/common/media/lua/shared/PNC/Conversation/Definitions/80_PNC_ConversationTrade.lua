local H = PNC.Conversation.DefinitionHelpers
for _, audience in ipairs({ "neutral", "member", "special" }) do
    H.RegisterSimple("trade", audience, { choices = {
        H.ContinueChoice("trade"),
    } })
end
return true
