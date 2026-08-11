PNC = PNC or {}
PNC.ItemUtility = PNC.ItemUtility or {}

local Utility = PNC.ItemUtility
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local StateCodec = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"

Utility.STATIC_SCHEMA = 2
if Utility.StaticSchema ~= Utility.STATIC_SCHEMA then
    Utility.StaticByTypeID = {}
    Utility.StaticSchema = Utility.STATIC_SCHEMA
else
    Utility.StaticByTypeID = Utility.StaticByTypeID or {}
end
Utility.Adapters = Utility.Adapters or {}

local function call(target, method, ...)
    if not target or type(target[method]) ~= "function" then return nil end
    local ok, value = pcall(target[method], target, ...)
    if not ok then return nil end
    return value
end

local function number(value, fallback)
    if type(value) == "number" then return value end
    if type(value) == "string" then
        local converted = tonumber(value)
        if converted ~= nil then return converted end
    end
    return fallback
end

local function boolean(value)
    return value == true or tostring(value) == "true"
end

local function addTags(output, source)
    if type(source) == "table" then
        for key, value in pairs(source) do
            local tag = type(key) == "number" and value or value == true and key or nil
            if tag then output[string.lower(tostring(tag))] = true end
        end
    elseif source and source.size and source.get then
        for index = 0, source:size() - 1 do
            output[string.lower(tostring(source:get(index)))] = true
        end
    end
end

local function probeFor(fullType)
    local item
    local ok
    if InventoryItemFactory then
        if InventoryItemFactory.CreateItem then
            ok, item = pcall(InventoryItemFactory.CreateItem, fullType)
            if not ok then item = nil end
        end
        if not item and InventoryItemFactory.instanceItem then
            ok, item = pcall(InventoryItemFactory.instanceItem, fullType)
            if not ok then item = nil end
        end
    end
    if not item and instanceItem then
        ok, item = pcall(instanceItem, fullType)
        if not ok then item = nil end
    end
    local scriptItem = getScriptManager and getScriptManager()
        and getScriptManager():getItem(fullType) or nil
    return item, scriptItem
end

local function normalizeNeedChange(value)
    value = number(value, 0) or 0
    -- ScriptItem stores vanilla need changes as percentage points (-15),
    -- while InventoryItem exposes normalized need units (-0.15).
    if math.abs(value) > 2 then return value / 100 end
    return value
end

local function readNumber(item, scriptItem, methods, fallback)
    for index = 1, #methods do
        local value = call(item, methods[index])
        if value == nil then value = call(scriptItem, methods[index]) end
        value = number(value)
        if value ~= nil then return value end
    end
    return fallback
end

local function readBoolean(item, scriptItem, methods)
    for index = 1, #methods do
        local value = call(item, methods[index])
        if value == nil then value = call(scriptItem, methods[index]) end
        if value ~= nil then return boolean(value) end
    end
    return false
end

local function hasAny(tags, values)
    for index = 1, #values do
        if tags[string.lower(values[index])] then return true end
    end
    return false
end

local function buildStatic(fullType, typeID)
    local item, scriptItem = probeFor(fullType)
    local tags = {}
    addTags(tags, call(item, "getTags"))
    addTags(tags, call(scriptItem, "getTags"))
    local hungerChange = readNumber(item, scriptItem,
        { "getHungerChange", "getHungChange" }, 0)
    local thirstChange = readNumber(item, scriptItem,
        { "getThirstChange" }, 0)
    hungerChange = normalizeNeedChange(hungerChange)
    thirstChange = normalizeNeedChange(thirstChange)
    local calories = readNumber(item, scriptItem, { "getCalories" }, 0)
    local typeString = string.lower(tostring(
        call(scriptItem, "getTypeString") or call(item, "getType") or ""))
    local bandage = hasAny(tags, { "bandage", "medicalbandage", "canbandage" })
        or readBoolean(item, scriptItem, { "canBandage", "isBandage" })
    for _, knownType in ipairs(PNC.Const and PNC.Const.BANDAGE_TYPES or {}) do
        if tostring(knownType) == fullType then bandage = true break end
    end
    local profile = {
        typeId = typeID,
        fullType = fullType,
        hunger = math.max(0, -(hungerChange or 0)),
        thirst = math.max(0, -(thirstChange or 0)),
        calories = math.max(0, calories or 0),
        negativeThirst = math.max(0, thirstChange or 0),
        useDelta = math.max(0, readNumber(item, scriptItem,
            { "getUseDelta" }, 0) or 0),
        offAge = readNumber(item, scriptItem, { "getOffAge" }),
        offAgeMax = readNumber(item, scriptItem, { "getOffAgeMax" }),
        food = typeString == "food" or hungerChange < 0
            or hasAny(tags, { "food", "edible" }),
        hydration = thirstChange < 0
            or readBoolean(item, scriptItem, { "isWaterSource" })
            or hasAny(tags, { "water", "drink", "hydration" }),
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
    cached = buildStatic(fullType, typeID)
    Utility.StaticByTypeID[typeID] = cached
    return cached
end

local function describe(profile, state, quantity)
    if not profile then return nil end
    state = type(state) == "table" and state or {}
    local usedDelta = number(state.usedDelta, number(state.uses))
    local useDelta = number(profile.useDelta, 0) or 0
    local remainingUses = useDelta > 0 and math.max(0,
        math.floor((usedDelta or 1) / useDelta + 0.0001)) or 1
    local age = number(state.age, 0) or 0
    local unsafe = state.rotten == true or state.poisoned == true
        or number(state.poisonPower, 0) > 0
    if profile.offAgeMax and profile.offAgeMax > 0
        and age >= profile.offAgeMax
    then unsafe = true end
    local expiry = 0
    if profile.offAgeMax and profile.offAgeMax > 0 then
        expiry = math.max(0, math.min(1, age / profile.offAgeMax))
    end
    return {
        typeId = profile.typeId,
        fullType = profile.fullType,
        quantity = math.max(1, math.floor(number(quantity, 1) or 1)),
        hunger = profile.hunger,
        thirst = profile.thirst,
        calories = profile.calories,
        negativeThirst = profile.negativeThirst,
        useDelta = useDelta,
        remainingUses = remainingUses,
        food = profile.food == true,
        hydration = profile.hydration == true and remainingUses > 0,
        bandage = profile.bandage == true,
        unsafe = unsafe,
        burnt = state.burnt == true,
        frozen = state.frozen == true,
        expiry = expiry,
        state = state,
    }
end

function Utility.DescribeCoreRecord(record)
    if type(record) ~= "table" then return nil end
    local typeID = tonumber(record[C.TYPE_ID])
    local spec = StateCodec.readState(record)
    local state = type(spec.itemState) == "table" and spec.itemState or {}
    state.usedDelta = spec.uses
    return describe(Utility.GetStatic(typeID), state, record[C.QUANTITY])
end

function Utility.DescribeNPCItem(item)
    if type(item) ~= "table" then return nil end
    local typeID = CoreInventory.getItemTypeId(item.type, false)
    if not typeID then return nil end
    local state = type(item.itemState) == "table" and item.itemState or {}
    local merged = {}
    for key, value in pairs(state) do merged[key] = value end
    merged.usedDelta = item.uses
    return describe(Utility.GetStatic(typeID, item.type), merged, item.stack)
end

function Utility.Supports(descriptor, request)
    if not descriptor or descriptor.unsafe then return false end
    if request.resourceKind == "FOOD" then
        return descriptor.food and descriptor.hunger > 0
    end
    if request.resourceKind == "HYDRATION" then
        return descriptor.hydration and descriptor.thirst > 0
    end
    if request.resourceKind == "MEDICAL" then
        return request.treatment == "BANDAGE" and descriptor.bandage == true
    end
    return false
end

return Utility
