if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Utility = PNC.ItemUtility
local H = Utility.Internal
local CoreInventory = H.CoreInventory

function H.BuildStatic(fullType, typeID)
    local item, scriptItem = H.ProbeFor(fullType)
    local tags = {}
    H.AddTags(tags, H.Call(item, "getTags"))
    H.AddTags(tags, H.Call(scriptItem, "getTags"))
    local hungerChange = H.ReadNumber(item, scriptItem,
        { "getHungerChange", "getHungChange" }, 0)
    local thirstChange = H.ReadNumber(item, scriptItem,
        { "getThirstChange" }, 0)
    hungerChange = H.NormalizeNeedChange(hungerChange)
    thirstChange = H.NormalizeNeedChange(thirstChange)
    local calories = H.ReadNumber(item, scriptItem, { "getCalories" }, 0)
    local typeString = string.lower(tostring(
        H.Call(scriptItem, "getTypeString")
            or H.Call(item, "getType") or ""))
    local bandage = H.HasAny(tags,
        { "bandage", "medicalbandage", "canbandage" })
        or H.ReadBoolean(item, scriptItem, { "canBandage", "isBandage" })
    for _, knownType in ipairs(PNC.Const and PNC.Const.BANDAGE_TYPES or {}) do
        if tostring(knownType) == fullType then
            bandage = true
            break
        end
    end
    local profile = {
        typeId = typeID,
        fullType = fullType,
        hunger = math.max(0, -(hungerChange or 0)),
        thirst = math.max(0, -(thirstChange or 0)),
        calories = math.max(0, calories or 0),
        negativeThirst = math.max(0, thirstChange or 0),
        useDelta = math.max(0, H.ReadNumber(item, scriptItem,
            { "getUseDelta" }, 0) or 0),
        offAge = H.ReadNumber(item, scriptItem, { "getOffAge" }),
        offAgeMax = H.ReadNumber(item, scriptItem, { "getOffAgeMax" }),
        food = typeString == "food" or hungerChange < 0
            or H.HasAny(tags, { "food", "edible" }),
        hydration = thirstChange < 0
            or H.ReadBoolean(item, scriptItem, { "isWaterSource" })
            or H.HasAny(tags, { "water", "drink", "hydration" }),
        bandage = bandage,
    }
    for index = 1, #Utility.Adapters do
        local ok, extension = pcall(Utility.Adapters[index], fullType,
            item, scriptItem, profile)
        if ok and type(extension) == "table" then
            for key, value in pairs(extension) do profile[key] = value end
        end
    end
    return profile
end

function Utility.RegisterAdapter(callback)
    if type(callback) ~= "function" then return false end
    Utility.Adapters[#Utility.Adapters + 1] = callback
    Utility.StaticByTypeID = {}
    return true
end

function Utility.GetStatic(typeID, fullType)
    typeID = math.floor(tonumber(typeID) or 0)
    if typeID <= 0 then return nil end
    local cached = Utility.StaticByTypeID[typeID]
    if cached then return cached end
    fullType = fullType or CoreInventory.getItemFullType(typeID)
    if not fullType then return nil end
    cached = H.BuildStatic(fullType, typeID)
    Utility.StaticByTypeID[typeID] = cached
    return cached
end

return Utility
