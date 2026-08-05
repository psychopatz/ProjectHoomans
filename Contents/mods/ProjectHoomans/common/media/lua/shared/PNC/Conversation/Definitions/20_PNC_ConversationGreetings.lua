local H = PNC.Conversation.DefinitionHelpers
local Registry = PNC.Conversation.Registry

Registry.RegisterBlock(H.PREFIX .. "hostile_parley", {
    schemaVersion = 1,
    ownerModID = H.MOD_ID,
    category = H.PREFIX .. "greetings",
    audiences = { "hostile" },
    priority = 100,
    weight = 100,
    textSource = H.Source("greetings", "hostile", "parley"),
    entryNode = "opening",
    nodes = {
        opening = {
            textKey = "opening",
            choices = {
                {
                    id = "ceasefire",
                    textKey = "choice.ceasefire",
                    outcomes = {
                        H.Outcome("requested", "response.ceasefire", {
                            close = true,
                            effects = { { type = "pnc:ceasefire" } },
                        }),
                    },
                },
            },
        },
    },
})

local timeWindows = {
    dawn = { 5, 6.5 }, sunrise = { 6.5, 12 }, sunset = { 12, 18 },
    dusk = { 18, 21 }, twilight = { 21, 5 },
}
local relationships = {
    FirstMeet = "neutral", Acquaintance = "neutral",
    Member = "member", Lover = "special",
}

for relationshipID, audience in pairs(relationships) do
    for timeID, window in pairs(timeWindows) do
        local slug = string.lower(relationshipID) .. "_" .. timeID
        local keys = {}
        for index = 1, 5 do keys[index] = string.format("greeting.%03d", index) end
        Registry.RegisterBlock(H.PREFIX .. "greeting_" .. slug, {
            schemaVersion = 1,
            ownerModID = H.MOD_ID,
            category = H.PREFIX .. "greetings",
            audiences = { audience },
            priority = 10,
            weight = 100,
            textSource = H.Source("greetings", audience, slug),
            entryNode = "opening",
            gates = {
                { type = "pnc:relationship_state", value = relationshipID },
                { type = "pnc:time", startHour = window[1], endHour = window[2] },
            },
            nodes = { opening = { textKeys = keys, choices = {} } },
        })
    end
end

return true
