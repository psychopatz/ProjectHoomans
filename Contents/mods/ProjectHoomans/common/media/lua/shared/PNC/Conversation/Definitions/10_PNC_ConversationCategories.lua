local H = PNC.Conversation.DefinitionHelpers
local Registry = PsychopatzCore.Conversation.Registry

local categories = {
    { "greetings", "UI_PsychopatzConversation_Category_Greetings", -100, true },
    { "wellbeing", "UI_PsychopatzConversation_Category_Wellbeing", 200 },
    { "small_talk", "UI_PsychopatzConversation_Category_SmallTalk", 300 },
    { "ask_about", "UI_PsychopatzConversation_Category_AskAbout", 400 },
    { "needs", "UI_PsychopatzConversation_Category_Needs", 500 },
    { "work_orders", "UI_PsychopatzConversation_Category_WorkOrders", 600 },
    { "personal", "UI_PsychopatzConversation_Category_Personal", 800 },
    { "relationship", "UI_PsychopatzConversation_Category_Relationship", 900 },
    { "set_territory", "UI_PsychopatzConversation_Category_SetTerritory", 950 },
    { "goodbye", "UI_PsychopatzConversation_Category_Goodbye", 10000, true },
}

for _, value in ipairs(categories) do
    local spec = {
        ownerModID = H.MOD_ID,
        labelKey = value[2],
        order = value[3],
        system = value[4] == true,
        ["repeat"] = value[5],
    }
    for key, extra in pairs(value[6] or {}) do
        spec[key] = extra
    end
    Registry.RegisterCategory(H.PREFIX .. value[1], spec)
end

return true
