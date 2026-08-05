local H = PNC.Conversation.DefinitionHelpers
for _, audience in ipairs({ "neutral", "member", "special" }) do
    H.RegisterSimple("ask_about", audience, { choices = {
        H.ContinueChoice("background"),
        H.ContinueChoice("skills"),
    } })
end
return true
