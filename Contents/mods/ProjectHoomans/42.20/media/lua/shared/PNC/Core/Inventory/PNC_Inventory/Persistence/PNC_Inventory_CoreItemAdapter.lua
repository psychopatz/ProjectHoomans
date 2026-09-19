-- Projects inventory ledger records into the Item API expected by PsychopatzCore.
local Internal = PNC.Inventory.Internal
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Profiles = require "PsychopatzCore/Inventory/PsychopatzItemTypeProfile"

local ItemAdapter = {}

local PSEUDO_ITEM_STATE_FIELDS = {
    "condition", "usedDelta", "favorite", "customName", "ammoCount",
    "age", "cooked", "burnt", "frozen", "freezingTime", "wetness",
    "bloodLevel", "dirtyness", "fluidAmount", "fluidType",
    "fluidPrimaryType", "fluidCapacity", "fluidInputLocked",
    "fluidCanPlayerEmpty", "fluidRainCatcher", "fluids", "hungChange",
    "thirstChange", "roundChambered", "jammed", "calories",
    "carbohydrates", "proteins", "lipids", "dangerousUncooked", "poison",
    "poisonDetectionLevel", "poisonLevelForRecipe", "poisonPower",
    "rottenTime", "cookedInMicrowave", "tainted", "fertilized",
    "fertilizedTime", "heat", "lastCookMinute", "cookingTime",
    "foodLastAgedHours", "foodCreatedAtHours", "foodRottenAtHours",
}

local PSEUDO_ITEM_METHODS = {
    getFluidContainer = function(self) return self.fluidState end,
    getFullType = function(self) return self.type end,
    getCondition = function(self) return self.condition end,
    getConditionMax = function(self)
        return self.condition and self.condition + 1 or nil
    end,
    getUsedDelta = function(self) return self.usedDelta end,
    isFavorite = function(self) return self.favorite end,
    isCustomName = function(self) return self.customName ~= nil end,
    getName = function(self) return self.customName end,
    getModData = function(self) return self.extraState end,
    getActualWeight = function(self) return self.actualWeight end,
    getWeight = function(self) return self.actualWeight end,
    getCurrentAmmoCount = function(self) return self.ammoCount end,
    getAge = function(self) return self.age end,
    isCooked = function(self) return self.cooked end,
    isBurnt = function(self) return self.burnt end,
    isFrozen = function(self) return self.frozen end,
    getFreezingTime = function(self) return self.freezingTime end,
    getHungChange = function(self) return self.hungChange end,
    getThirstChange = function(self) return self.thirstChange end,
    getCalories = function(self) return self.calories end,
    getCarbohydrates = function(self) return self.carbohydrates end,
    getProteins = function(self) return self.proteins end,
    getLipids = function(self) return self.lipids end,
    isbDangerousUncooked = function(self) return self.dangerousUncooked end,
    isPoison = function(self) return self.poison end,
    getPoisonDetectionLevel = function(self)
        return self.poisonDetectionLevel
    end,
    getPoisonLevelForRecipe = function(self)
        return self.poisonLevelForRecipe
    end,
    getPoisonPower = function(self) return self.poisonPower end,
    getRottenTime = function(self) return self.rottenTime end,
    isCookedInMicrowave = function(self) return self.cookedInMicrowave end,
    isTainted = function(self) return self.tainted end,
    isFertilized = function(self) return self.fertilized end,
    getFertilizedTime = function(self) return self.fertilizedTime end,
    getHeat = function(self) return self.heat end,
    getLastCookMinute = function(self) return self.lastCookMinute end,
    getCookingTime = function(self) return self.cookingTime end,
    getWetness = function(self) return self.wetness end,
    getBloodLevel = function(self) return self.bloodLevel end,
    getDirtiness = function(self) return self.dirtyness end,
}

local function choose(preferred, fallback)
    return preferred ~= nil and preferred or fallback
end

local function buildPseudoItemData(item, state)
    local pseudo = {
        type = item.type, condition = choose(item.cond, state.condition),
        usedDelta = choose(item.uses, state.usedDelta),
        favorite = item.fav == true or state.favorite == true,
        customName = item.customName or state.customName,
        ammoCount = choose(item.ammoCount, state.ammoCount),
        age = state.age, cooked = state.cooked, burnt = state.burnt,
        frozen = state.frozen, freezingTime = state.freezingTime,
        hungChange = state.hungChange, thirstChange = state.thirstChange,
        calories = state.calories, carbohydrates = state.carbohydrates,
        proteins = state.proteins, lipids = state.lipids,
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
    for i = 1, #PSEUDO_ITEM_STATE_FIELDS do
        pseudo.extraState[PSEUDO_ITEM_STATE_FIELDS[i]] = nil
    end
    if Internal.countMapEntries(pseudo.extraState) <= 0 then pseudo.extraState = nil end
    if state.fluidAmount ~= nil or state.fluidType ~= nil
        or state.fluidCapacity ~= nil or state.fluids ~= nil
    then
        pseudo.fluidState = state
    end
    return pseudo
end

local function attachPseudoItemMethods(pseudo)
    for name, method in pairs(PSEUDO_ITEM_METHODS) do
        pseudo[name] = method
    end
end

local function setPseudoItemCapabilities(pseudo, profile)
    local capabilities = profile and profile.capabilities or {}
    pseudo.isWeapon = capabilities.weapon == true
    pseudo.isFood = capabilities.food == true
    pseudo.isClothing = capabilities.clothing == true
    pseudo.isDrainable = capabilities.drainable == true
    if not profile then
        -- Keep explicit family data for item types without a static profile.
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
end

function ItemAdapter.pseudoItem(item)
    local state = type(item.itemState) == "table" and item.itemState or {}
    local profile = Profiles.Get(item.type)
    local pseudo = buildPseudoItemData(item, state)
    attachPseudoItemMethods(pseudo)
    setPseudoItemCapabilities(pseudo, profile)
    return pseudo
end

return ItemAdapter
