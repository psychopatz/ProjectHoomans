PNC = PNC or {}
PNC.MoraleModifierDefinitions = PNC.MoraleModifierDefinitions or {}

local Registry = PNC.MoraleModifierDefinitions
Registry.ORDER = Registry.ORDER or {}
Registry.BY_ID = Registry.BY_ID or {}

function Registry.Register(definition)
    if type(definition) ~= "table" then return false, "INVALID_MODIFIER" end
    local id = tostring(definition.id or "")
    if id == "" then return false, "MODIFIER_ID_REQUIRED" end
    if Registry.BY_ID[id] then return false, "MODIFIER_ALREADY_REGISTERED" end
    definition.id = id
    definition.weight = tonumber(definition.weight) or 1
    definition.worsenPerDay = tonumber(definition.worsenPerDay) or 0
    Registry.BY_ID[id] = definition
    Registry.ORDER[#Registry.ORDER + 1] = id
    return true, definition
end

function Registry.Get(id) return Registry.BY_ID[tostring(id or "")] end
function Registry.List()
    local output = {}
    for _, id in ipairs(Registry.ORDER) do output[#output + 1] = Registry.BY_ID[id] end
    return output
end

local BUILT_INS = {
    { id = "housing", translationKey = "UI_PNC_Morale_Housing",
        iconKey = "morale.housing", weight = 1.2, worsenPerDay = 0.03 },
    { id = "sleep_quality", translationKey = "UI_PNC_Morale_SleepQuality",
        iconKey = "morale.sleep", weight = 1.0, worsenPerDay = 0.02 },
    { id = "food_quality", translationKey = "UI_PNC_Morale_FoodQuality",
        iconKey = "morale.food", weight = 0.9 },
    { id = "recreation", translationKey = "UI_PNC_Morale_Recreation",
        iconKey = "morale.recreation", weight = 0.8, worsenPerDay = 0.015 },
    { id = "social", translationKey = "UI_PNC_Morale_Social",
        iconKey = "morale.social", weight = 0.9 },
    { id = "safety", translationKey = "UI_PNC_Morale_Safety",
        iconKey = "morale.safety", weight = 1.3, worsenPerDay = 0.04 },
    { id = "employment", translationKey = "UI_PNC_Morale_Employment",
        iconKey = "morale.employment", weight = 0.7, worsenPerDay = 0.01 },
}
for _, definition in ipairs(BUILT_INS) do
    if not Registry.BY_ID[definition.id] then Registry.Register(definition) end
end

return Registry
