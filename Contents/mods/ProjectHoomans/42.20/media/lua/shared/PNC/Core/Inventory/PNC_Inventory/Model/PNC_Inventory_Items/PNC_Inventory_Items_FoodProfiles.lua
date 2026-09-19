-- Food-specific lifecycle profiles and their injectable provider contract.
local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"

Internal.ItemFoodProfileCache = Internal.ItemFoodProfileCache or {}
Internal.FoodProfileProvider = Internal.FoodProfileProvider or nil

local function profileNumber(item, scriptItem, methodName)
    local value = Util.call(item, methodName)
    if value == nil then value = Util.call(scriptItem, methodName) end
    value = tonumber(value)
    return value
end

local function profileString(item, scriptItem, methodName)
    local value = Util.call(item, methodName)
    if value == nil then value = Util.call(scriptItem, methodName) end
    value = value and tostring(value) or nil
    return value ~= "" and value or nil
end

function Inventory.RegisterFoodProfileProvider(callback)
    Internal.FoodProfileProvider = type(callback) == "function"
        and callback or nil
    Internal.ItemFoodProfileCache = {}
end

function Internal.getFoodProfile(fullType)
    if type(Internal.normalizeString) ~= "function" then return nil end
    fullType = Internal.normalizeString(fullType)
    if not fullType then return nil end
    local cached = Internal.ItemFoodProfileCache[fullType]
    local provided
    local item
    local scriptItem
    local typeString
    local isFood
    if cached ~= nil then return cached end
    if Internal.FoodProfileProvider then
        local ok
        -- Profile providers are an add-on extension point. Keep protection
        -- around only the provider callback, not the built-in lookup path.
        ok, provided = pcall(Internal.FoodProfileProvider, fullType)
        if ok and type(provided) == "table" then
            Internal.ItemFoodProfileCache[fullType] = provided
            return provided
        end
    end
    item = Internal.createItemProbe(fullType)
    scriptItem = getScriptManager and getScriptManager().getItem
        and getScriptManager():getItem(fullType) or nil
    typeString = tostring(Util.call(item, "getTypeString") or "")
    if typeString == "" then
        typeString = tostring(Util.call(scriptItem, "getTypeString") or "")
    end
    isFood = typeString:lower() == "food"
        or Util.call(item, "isFood") == true
        or Util.call(item, "IsFood") == true
        or item and item.isFood == true
        or Util.call(item, "getAge") ~= nil
    if not isFood then
        cached = { food = false, fullType = fullType }
    else
        cached = {
            food = true,
            fullType = fullType,
            offAge = profileNumber(item, scriptItem, "getOffAge"),
            offAgeMax = profileNumber(item, scriptItem, "getOffAgeMax"),
            replaceOnRotten = profileString(
                item, scriptItem, "getReplaceOnRotten"
            ),
        }
    end
    Internal.ItemFoodProfileCache[fullType] = cached
    return cached
end

function Inventory.GetFoodProfile(fullType)
    return Internal.getFoodProfile(fullType)
end

return Inventory
