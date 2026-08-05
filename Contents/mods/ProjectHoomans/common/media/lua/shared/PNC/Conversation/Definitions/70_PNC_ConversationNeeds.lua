local H = PNC.Conversation.DefinitionHelpers
for _, audience in ipairs({ "neutral", "member", "special" }) do
    H.RegisterSimple("needs", audience, {
        nodes = {
            opening = {
                textKey = "opening",
                choices = {
                    H.ContinueChoice("supplies"),
                    H.ContinueChoice("medical"),
                    {
                        id = "gift",
                        textKey = "choice.gift",
                        outcomes = {
                            H.Outcome("prompt", "response.gift", {
                                next = "gift",
                            }),
                        },
                    },
                },
            },
            gift = {
                textKey = "gift.opening",
                choices = {
                    H.ContinueChoice("gift_return"),
                },
            },
        },
    })
end
return true
