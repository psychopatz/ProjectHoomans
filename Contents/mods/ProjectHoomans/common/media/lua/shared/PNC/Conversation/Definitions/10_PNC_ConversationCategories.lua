local H = PNC.Conversation.DefinitionHelpers
local Registry = PNC.Conversation.Registry
local categorySource = H.Source("system", "shared", "categories")

local categories = {
    { "greetings", "category.greetings", -100, true },
    { "whats_up", "category.whats_up", 100, false,
        { scope = "pair", oncePerDay = true } },
    { "wellbeing", "category.wellbeing", 200 },
    { "small_talk", "category.small_talk", 300 },
    { "ask_about", "category.ask_about", 400 },
    { "needs", "category.needs", 500 },
    { "work_orders", "category.work_orders", 600 },
    { "trade", "category.trade", 700 },
    { "personal", "category.personal", 800 },
    { "relationship", "category.relationship", 900 },
    { "goodbye", "category.goodbye", 10000, true },
}

for _, value in ipairs(categories) do
    Registry.RegisterCategory(H.PREFIX .. value[1], {
        ownerModID = H.MOD_ID,
        labelKey = value[2],
        order = value[3],
        system = value[4] == true,
        ["repeat"] = value[5],
        textSource = categorySource,
    })
end

return true
