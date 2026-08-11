local Internal = PNC.Inventory.Internal
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"

local StateCodec = {}

function StateCodec.pseudoItem(item)
    local state = type(item.itemState) == "table" and item.itemState or {}
    local pseudo = {
        type = item.type, condition = item.cond or state.condition,
        usedDelta = item.uses or state.usedDelta,
        favorite = item.fav == true or state.favorite == true,
        customName = item.customName or state.customName,
        ammoCount = item.ammoCount or state.ammoCount,
        age = state.age, cooked = state.cooked, burnt = state.burnt,
        frozen = state.frozen, freezingTime = state.freezingTime,
        wetness = state.wetness, bloodLevel = state.bloodLevel,
        dirtyness = state.dirtyness,
        actualWeight = Internal.getItemWeight(item.type),
        extraState = Util.copy(state),
    }
    local known = { "condition", "usedDelta", "favorite", "customName",
        "ammoCount", "age", "cooked", "burnt", "frozen", "freezingTime",
        "wetness", "bloodLevel", "dirtyness" }
    for i = 1, #known do pseudo.extraState[known[i]] = nil end
    if Internal.countMapEntries(pseudo.extraState) <= 0 then pseudo.extraState = nil end
    function pseudo:getFullType() return self.type end
    function pseudo:getCondition() return self.condition end
    function pseudo:getConditionMax() return self.condition and self.condition + 1 or nil end
    function pseudo:getUsedDelta() return self.usedDelta end
    function pseudo:isFavorite() return self.favorite end
    function pseudo:isCustomName() return self.customName ~= nil end
    function pseudo:getName() return self.customName end
    function pseudo:getModData() return self.extraState end
    function pseudo:getActualWeight() return self.actualWeight end
    function pseudo:getWeight() return self.actualWeight end
    function pseudo:getCurrentAmmoCount() return self.ammoCount end
    function pseudo:getAge() return self.age end
    function pseudo:isCooked() return self.cooked end
    function pseudo:isBurnt() return self.burnt end
    function pseudo:isFrozen() return self.frozen end
    function pseudo:getFreezingTime() return self.freezingTime end
    function pseudo:getWetness() return self.wetness end
    function pseudo:getBloodLevel() return self.bloodLevel end
    function pseudo:getDirtyness() return self.dirtyness end
    if pseudo.ammoCount ~= nil then pseudo.isWeapon = true end
    if pseudo.age ~= nil or pseudo.cooked ~= nil or pseudo.burnt ~= nil then pseudo.isFood = true end
    if pseudo.wetness ~= nil or pseudo.bloodLevel ~= nil then pseudo.isClothing = true end
    if pseudo.usedDelta ~= nil then pseudo.isDrainable = true end
    return pseudo
end

function StateCodec.metadata(item)
    return { item.id, math.max(1, math.floor(tonumber(item.stack) or 1)),
        item.container ~= "root" and item.container or nil, item.bagContainer,
        item.maxWeight, item.weightReduction, item.wearableSlot, item.templateKey,
        item.preferredContainer, item.wornSlot, item.attachedSlot, item.equipSlot,
        item.interactionLocked == true or nil, item.interactionLockReason,
        item.identityNPCId, item.identityNPCName }
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
    if Util.hasFlag(flags, C.FLAG_FOOD) then
        local food = data[cursor] or {}
        spec.itemState.age, spec.itemState.cooked = food[1], food[2]
        spec.itemState.burnt, spec.itemState.frozen = food[3], food[4]
        spec.itemState.freezingTime, cursor = food[5], cursor + 1
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
