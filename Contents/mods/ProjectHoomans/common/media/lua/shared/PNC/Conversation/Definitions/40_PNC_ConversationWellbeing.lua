local H = PNC.Conversation.DefinitionHelpers
for _, audience in ipairs({ "neutral", "member", "special" }) do
    H.RegisterSimple("wellbeing", audience, { choices = {
        H.ContinueChoice("condition", {
            { type = "pnc:relationship", approval = 1, familiarity = 1 },
        }),
        H.ContinueChoice("offer_help", {
            { type = "pnc:relationship", approval = 2, respect = 1 },
        }),
    } })
end
return true
