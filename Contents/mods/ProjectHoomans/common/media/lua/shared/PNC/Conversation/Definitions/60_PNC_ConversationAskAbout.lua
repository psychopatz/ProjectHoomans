local H = PNC.Conversation.DefinitionHelpers
for _, audience in ipairs({ "neutral", "member", "special" }) do
    H.RegisterSimple("ask_about", audience, "social/ask_about/" .. audience, { textOwner = "PsychopatzCore", choices = {
        H.ContinueChoice("background"),
        H.ContinueChoice("skills"),
    } })
end
return true
