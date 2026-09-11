local Internal = PNC.Inventory.Internal
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Profiles = require "PsychopatzCore/Inventory/PsychopatzItemTypeProfile"

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
}

local FOOD_OPTIONAL_ORDER = {
    "dangerousUncooked", "poison", "poisonDetectionLevel",
    "poisonLevelForRecipe", "poisonPower", "rottenTime",
    "cookedInMicrowave", "tainted", "fertilized", "fertilizedTime",
    "heat", "lastCookMinute", "cookingTime", "foodLastAgedHours",
    "foodCreatedAtHours",
}

local function choose(preferred, fallback)
    return preferred ~= nil and preferred or fallback
end

function StateCodec.pseudoItem(item)
    local state = type(item.itemState) == "table" and item.itemState or {}
    local profile = Profiles.Get(item.type)
    local capabilities = profile and profile.capabilities or {}
    local pseudo = {
        type = item.type, condition = choose(item.cond, state.condition),
        usedDelta = choose(item.uses, state.usedDelta),
        favorite = item.fav == true or state.favorite == true,
        customName = item.customName or state.customName,
        ammoCount = choose(item.ammoCount, state.ammoCount),
        age = state.age, cooked = state.cooked, burnt = state.burnt,
        frozen = state.frozen, freezingTime = state.freezingTime,
        hungChange = state.hungChange, thirstChange = state.thirstChange,
        dangerousUncooked = state.dangerousUncooked,
        poison = state.poison,
        poisonDetectionLevel = state.poisonDetectionLevel,
        poisonLevelForRecipe = state.poisonLevelForRecipe,
        poisonPower = state.poisonPower,
        rottenTime = state.rottenTime,
        cookedInMicrowave = state.cookedInMicrowave,
        tainted = state.tainted,
        fertilized = state.fertilized,
        fertilizedTime = state.fertilizedTime,
        heat = state.heat,
        lastCookMinute = state.lastCookMinute,
        cookingTime = state.cookingTime,
        foodLastAgedHours = state.foodLastAgedHours,
        foodCreatedAtHours = state.foodCreatedAtHours,
        wetness = state.wetness, bloodLevel = state.bloodLevel,
        dirtyness = state.dirtyness,
        actualWeight = Internal.getItemWeight(item.type),
        extraState = Util.copy(state),
    }
    local known = { "condition", "usedDelta", "favorite", "customName",
        "ammoCount", "age", "cooked", "burnt", "frozen", "freezingTime",
        "wetness", "bloodLevel", "dirtyness", "fluidAmount", "fluidType",
        "fluidPrimaryType", "fluidCapacity", "fluidInputLocked",
        "fluidCanPlayerEmpty", "fluidRainCatcher", "fluids",
        "hungChange", "thirstChange", "roundChambered", "jammed",
        "dangerousUncooked", "poison", "poisonDetectionLevel",
        "poisonLevelForRecipe", "poisonPower", "rottenTime",
        "cookedInMicrowave", "tainted", "fertilized", "fertilizedTime",
        "heat", "lastCookMinute", "cookingTime", "foodLastAgedHours",
        "foodCreatedAtHours",
        "foodRottenAtHours",
    }
    for i = 1, #known do pseudo.extraState[known[i]] = nil end
    if Internal.countMapEntries(pseudo.extraState) <= 0 then pseudo.extraState = nil end
    if state.fluidAmount ~= nil or state.fluidType ~= nil
        or state.fluidCapacity ~= nil or state.fluids ~= nil
    then
        pseudo.fluidState = state
    end
    function pseudo:getFluidContainer() return self.fluidState end
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
    function pseudo:getHungChange() return self.hungChange end
    function pseudo:getThirstChange() return self.thirstChange end
    function pseudo:isbDangerousUncooked() return self.dangerousUncooked end
    function pseudo:isPoison() return self.poison end
    function pseudo:getPoisonDetectionLevel() return self.poisonDetectionLevel end
    function pseudo:getPoisonLevelForRecipe() return self.poisonLevelForRecipe end
    function pseudo:getPoisonPower() return self.poisonPower end
    function pseudo:getRottenTime() return self.rottenTime end
    function pseudo:isCookedInMicrowave() return self.cookedInMicrowave end
    function pseudo:isTainted() return self.tainted end
    function pseudo:isFertilized() return self.fertilized end
    function pseudo:getFertilizedTime() return self.fertilizedTime end
    function pseudo:getHeat() return self.heat end
    function pseudo:getLastCookMinute() return self.lastCookMinute end
    function pseudo:getCookingTime() return self.cookingTime end
    function pseudo:getWetness() return self.wetness end
    function pseudo:getBloodLevel() return self.bloodLevel end
    function pseudo:getDirtiness() return self.dirtyness end
    pseudo.isWeapon = capabilities.weapon == true
    pseudo.isFood = capabilities.food == true
    pseudo.isClothing = capabilities.clothing == true
    pseudo.isDrainable = capabilities.drainable == true
    if not profile then
        -- Abstract records can contain an explicit state family without a
        -- native definition probe (for example a dynamically authored
        -- magazine).  Preserve that explicit ledger data until its owner
        -- registers a static profile; neutral native getters never reach
        -- this path.
        if pseudo.ammoCount ~= nil then pseudo.isWeapon = true end
        if pseudo.age ~= nil or pseudo.cooked ~= nil or pseudo.burnt ~= nil
            or pseudo.dangerousUncooked ~= nil or pseudo.poison ~= nil
            or pseudo.poisonPower ~= nil or pseudo.tainted ~= nil
            or pseudo.fertilized ~= nil or pseudo.foodLastAgedHours ~= nil
            or pseudo.foodCreatedAtHours ~= nil
            or pseudo.poisonDetectionLevel ~= nil
            or pseudo.poisonLevelForRecipe ~= nil
            or pseudo.rottenTime ~= nil
            or pseudo.cookedInMicrowave ~= nil
            or pseudo.fertilizedTime ~= nil
            or pseudo.heat ~= nil
            or pseudo.lastCookMinute ~= nil
            or pseudo.cookingTime ~= nil
        then
            pseudo.isFood = true
        end
        if pseudo.wetness ~= nil or pseudo.bloodLevel ~= nil then
            pseudo.isClothing = true
        end
        if pseudo.usedDelta ~= nil then pseudo.isDrainable = true end
    end
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
