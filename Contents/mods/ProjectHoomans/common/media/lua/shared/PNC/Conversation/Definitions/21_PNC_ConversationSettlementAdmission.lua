local H = PNC.Conversation.DefinitionHelpers
local Registry = PNC.Conversation.Registry

Registry.RegisterBlock(H.PREFIX .. "settlement_admission", {
    schemaVersion = 1,
    ownerModID = H.MOD_ID,
    category = H.PREFIX .. "greetings",
    audiences = { "neutral", "member", "special" },
    priority = 1000,
    weight = 100,
    textSource = H.Source(
        "greetings",
        "settlement_admission",
        "arrival"
    ),
    entryNode = "opening",
    gates = { { type = "pnc:settlement_visit" } },
    nodes = {
        opening = {
            textKeys = {
                "opening.001", "opening.002", "opening.003",
            },
            choices = {},
        },
    },
})

return true
