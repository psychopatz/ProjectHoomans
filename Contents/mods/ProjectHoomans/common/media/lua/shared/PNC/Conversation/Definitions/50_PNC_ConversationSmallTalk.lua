local H = PNC.Conversation.DefinitionHelpers
for _, audience in ipairs({ "neutral", "member", "special" }) do
    H.RegisterSimple("small_talk", audience, "social/small_talk/" .. audience, { textOwner = "PsychopatzCore", choices = {
        H.ContinueChoice("weather"),
        H.ContinueChoice("quiet_day", {
            { type = "pnc:relationship", familiarity = 1 },
        }),
    } })
end
return true
