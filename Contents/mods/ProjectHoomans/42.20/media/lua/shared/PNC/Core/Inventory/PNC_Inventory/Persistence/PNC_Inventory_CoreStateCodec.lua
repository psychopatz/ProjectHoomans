local Internal = PNC.Inventory.Internal
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local ItemAdapter = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreItemAdapter"

local StateCodec = {}

local FOOD_OPTIONAL = {
    dangerousUncooked = 1,
    poison = 2,
    poisonDetectionLevel = 4,
    poisonLevelForRecipe = 8,
    poisonPower = 16,
    rottenTime = 32,
    cookedInMicrowave = 64,
    tainted = 128,
    fertilized = 256,
    fertilizedTime = 512,
    heat = 1024,
    lastCookMinute = 2048,
    cookingTime = 4096,
    foodLastAgedHours = 8192,
    foodCreatedAtHours = 16384,
    calories = 32768,
    carbohydrates = 65536,
    proteins = 131072,
    lipids = 262144,
}

local FOOD_OPTIONAL_ORDER = {
    "dangerousUncooked", "poison", "poisonDetectionLevel",
    "poisonLevelForRecipe", "poisonPower", "rottenTime",
    "cookedInMicrowave", "tainted", "fertilized", "fertilizedTime",
    "heat", "lastCookMinute", "cookingTime", "foodLastAgedHours",
    "foodCreatedAtHours", "calories", "carbohydrates", "proteins", "lipids",
}

function StateCodec.pseudoItem(item)
    return ItemAdapter.pseudoItem(item)
end

function StateCodec.metadata(item)
    return { item.id, math.max(1, math.floor(tonumber(item.stack) or 1)),
        item.container ~= "root" and item.container or nil, item.bagContainer,
        item.maxWeight, item.weightReduction, item.wearableSlot, item.templateKey,
        item.preferredContainer, item.wornSlot, item.attachedSlot, item.equipSlot,
        item.interactionLocked == true or nil, item.interactionLockReason,
        item.identityNPCId, item.identityNPCName }
end

function StateCodec.validateCoreRecord(coreRecord)
    if type(coreRecord) ~= "table" then
        return false, "record_not_table"
    end
    local itemRecord = CoreInventory.ItemRecord
    if type(itemRecord) ~= "table"
        or type(itemRecord.validate) ~= "function"
    then
        return false, "core_record_validator_unavailable"
    end
    local valid, reason = itemRecord.validate(coreRecord)
    if not valid then return false, reason or "invalid_core_record" end

    local flags = tonumber(coreRecord[C.FLAGS]) or 0
    local data = coreRecord[C.STATE]
    local cursor = 1
    local chunk
    if Util.hasFlag(flags, C.FLAG_CONDITION) then cursor = cursor + 1 end
    if Util.hasFlag(flags, C.FLAG_USED_DELTA) then cursor = cursor + 1 end
    if Util.hasFlag(flags, C.FLAG_CUSTOM_NAME) then cursor = cursor + 1 end
    if Util.hasFlag(flags, C.FLAG_MOD_DATA) then
        chunk = data[cursor]
        if chunk ~= nil and type(chunk) ~= "table" then
            return false, "invalid_mod_data_state"
        end
        cursor = cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_CUSTOM_WEIGHT) then cursor = cursor + 1 end
    if Util.hasFlag(flags, C.FLAG_FLUID) then
        chunk = data[cursor]
        if chunk ~= nil and type(chunk) ~= "table" then
            return false, "invalid_fluid_state"
        end
        cursor = cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_FOOD) then
        chunk = data[cursor]
        if chunk ~= nil and type(chunk) ~= "table" then
            return false, "invalid_food_state"
        end
        cursor = cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_AMMO) then
        chunk = data[cursor]
        if chunk ~= nil and type(chunk) ~= "table" then
            return false, "invalid_ammo_state"
        end
        cursor = cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_CLOTHING) then
        chunk = data[cursor]
        if chunk ~= nil and type(chunk) ~= "table" then
            return false, "invalid_clothing_state"
        end
    end
    return true
end

function StateCodec.readValidatedState(coreRecord)
    local valid, reason = StateCodec.validateCoreRecord(coreRecord)
    if not valid then return nil, reason end
    return StateCodec.readState(coreRecord)
end

function StateCodec.readState(coreRecord)
    local flags, data = coreRecord[C.FLAGS], coreRecord[C.STATE]
    local cursor = 1
    local spec = { itemState = {} }
    if Util.hasFlag(flags, C.FLAG_CONDITION) then spec.cond, cursor = data[cursor], cursor + 1 end
    if Util.hasFlag(flags, C.FLAG_USED_DELTA) then spec.uses, cursor = data[cursor], cursor + 1 end
    if Util.hasFlag(flags, C.FLAG_FAVORITE) then spec.fav = true end
    if Util.hasFlag(flags, C.FLAG_CUSTOM_NAME) then spec.customName, cursor = data[cursor], cursor + 1 end
    if Util.hasFlag(flags, C.FLAG_MOD_DATA) then
        for key, value in pairs(data[cursor] or {}) do spec.itemState[key] = Util.copy(value) end
        cursor = cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_CUSTOM_WEIGHT) then cursor = cursor + 1 end
    if Util.hasFlag(flags, C.FLAG_FLUID) then
        local fluid = data[cursor] or {}
        for key, value in pairs(fluid) do
            spec.itemState[key] = Util.copy(value)
        end
        cursor = cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_FOOD) then
        local food = data[cursor] or {}
        spec.itemState.age, spec.itemState.cooked = food[1], food[2]
        spec.itemState.burnt, spec.itemState.frozen = food[3], food[4]
        spec.itemState.freezingTime = food[5]
        spec.itemState.hungChange, spec.itemState.thirstChange = food[6], food[7]
        local optionalFlags = tonumber(food[8]) or 0
        local optionalCursor = 9
        local key
        for i = 1, #FOOD_OPTIONAL_ORDER do
            key = FOOD_OPTIONAL_ORDER[i]
            if Util.hasFlag(optionalFlags, FOOD_OPTIONAL[key]) then
                spec.itemState[key] = food[optionalCursor]
                optionalCursor = optionalCursor + 1
            end
        end
        cursor = cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_AMMO) then
        local ammo = data[cursor] or {}
        spec.ammoCount, spec.itemState.roundChambered = ammo[1], ammo[2]
        spec.itemState.jammed, cursor = ammo[3], cursor + 1
    end
    if Util.hasFlag(flags, C.FLAG_CLOTHING) then
        local clothing = data[cursor] or {}
        spec.itemState.wetness, spec.itemState.bloodLevel = clothing[1], clothing[2]
        spec.itemState.dirtyness = clothing[3]
    end
    if Internal.countMapEntries(spec.itemState) <= 0 then spec.itemState = nil end
    return spec
end

function StateCodec.applyMetadata(spec, meta, fullType)
    spec.id, spec.stack, spec.type = meta[1], meta[2], fullType
    spec.container, spec.bagContainer = meta[3] or "root", meta[4]
    spec.maxWeight, spec.weightReduction = meta[5], meta[6]
    spec.wearableSlot, spec.templateKey = meta[7], meta[8]
    spec.preferredContainer, spec.wornSlot = meta[9], meta[10]
    spec.attachedSlot, spec.equipSlot = meta[11], meta[12]
    spec.interactionLocked, spec.interactionLockReason = meta[13] == true, meta[14]
    spec.identityNPCId, spec.identityNPCName = meta[15], meta[16]
end

return StateCodec
