if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Utility = PNC.ItemUtility
local H = Utility.Internal
local CoreInventory = H.CoreInventory
local C = H.Constants
local StateCodec = H.StateCodec
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"

local function clampFraction(value)
    return math.max(0, math.min(1, tonumber(value) or 0))
end

local function effectiveState(profile, state)
    local raw = type(state) == "table" and state or {}
    local resolver = PNC.Inventory and PNC.Inventory.ResolveItemState
    local resolved
    if type(resolver) == "function" and profile
        and profile.fullType
    then
        resolved = resolver({ type = profile.fullType, itemState = raw })
        if type(resolved) == "table" then return resolved end
    end
    return raw
end

local function currentFoodValues(profile, state, explicitState, status,
    remainingFraction)
    local hungerChange = H.Number(explicitState.hungChange,
        H.Number(state.hungChange))
    local thirstChange = H.Number(explicitState.thirstChange,
        H.Number(state.thirstChange))
    local hunger = profile.hunger * remainingFraction
    local thirst = profile.thirst * remainingFraction
    local negativeThirst = profile.negativeThirst * remainingFraction
    local baseHunger = profile.hunger
    local baseThirst = profile.thirst
    local baseNegativeThirst = profile.negativeThirst
    local hungerCap = baseHunger * remainingFraction
    if hungerChange ~= nil then
        if state.cooked == true then
            hungerChange = hungerChange * 1.3
            hungerCap = hungerCap * 1.3
        elseif status.rotten then
            hungerChange = hungerChange / 2.2
            hungerCap = hungerCap / 2.2
        elseif status.stale then
            hungerChange = hungerChange / 1.3
            hungerCap = hungerCap / 1.3
        end
        hunger = math.min(math.max(0, -hungerChange),
            math.max(0, hungerCap))
    end
    if thirstChange ~= nil then
        if state.cooked == true then
            thirstChange = thirstChange / 2
        end
        thirst = math.min(math.max(0, -thirstChange),
            math.max(0, baseThirst * remainingFraction))
        negativeThirst = math.min(math.max(0, thirstChange),
            math.max(0, baseNegativeThirst * remainingFraction))
    end
    return hunger, thirst, negativeThirst
end

function H.Describe(profile, state, quantity)
    if not profile then return nil end
    local explicitState = type(state) == "table" and state or {}
    state = effectiveState(profile, state)
    local usedDelta = H.Number(state.usedDelta, H.Number(state.uses))
    local useDelta = H.Number(profile.useDelta, 0) or 0
    local remainingFraction = profile.food == true and usedDelta ~= nil
        and clampFraction((usedDelta or 0) / math.max(0.000001,
            H.Number(profile.maxUsedDelta, 1) or 1)) or 1
    local remainingUses = profile.food == true
        and (remainingFraction > 0.000001 and 1 or 0)
        or useDelta > 0 and math.max(0,
            math.floor((usedDelta or 1) / useDelta + 0.0001)) or 1
    local age = H.Number(state.age, 0) or 0
    local foodStatus = Portable.GetFoodStatus(state, profile)
    local hunger
    local thirst
    local negativeThirst
    local fluidAmount
    local fluidType
    local fluidHydration
    local fluidSafe
    hunger, thirst, negativeThirst = currentFoodValues(
        profile, state, explicitState, foodStatus, remainingFraction
    )
    fluidAmount = H.Number(state.fluidAmount)
    fluidType = tostring(state.fluidPrimaryType or state.fluidType or "")
    fluidHydration = profile.fluidHydration == true
        and profile.fluidContainer == true
    if fluidHydration and fluidAmount and fluidAmount > 0.000001 then
        thirst = fluidAmount
            * (H.Number(profile.hydrationYieldPerLiter, 0.50) or 0.50)
    end
    fluidSafe = not fluidHydration
        or fluidType == ""
        or fluidType == "Water"
        or fluidType == "CarbonatedWater"
    if fluidType == "TaintedWater" then fluidSafe = false end
    local unsafe = state.rotten == true or state.poisoned == true
        or state.poison == true or state.tainted == true
        or H.Number(state.poisonPower, 0) > 0
        or foodStatus.rotten
    local expiry = 0
    if profile.offAgeMax and profile.offAgeMax > 0
        and profile.offAgeMax < 1000000000
    then
        expiry = math.max(0, math.min(1, age / profile.offAgeMax))
    end
    local burntMultiplier = state.burnt == true and 0.20 or 1
    local function currentNutrient(field)
        local current = H.Number(explicitState[field])
        local baseline = H.Number(profile[field], 0) or 0
        if current == nil then return baseline * remainingFraction end
        -- A stale compact record may carry the original nutrient value while
        -- usedDelta says only part of the food remains. Never award more than
        -- the remaining share of the pristine item.
        if baseline >= 0 then
            return math.min(current, baseline * remainingFraction)
        end
        return current
    end
    return {
        typeId = profile.typeId,
        fullType = profile.fullType,
        quantity = math.max(1, math.floor(H.Number(quantity, 1) or 1)),
        -- Descriptor values are the contribution used by selectors and
        -- provisioning. Consumption applies only the partial-use fraction,
        -- so burnt items are not accidentally reduced twice.
        hunger = hunger * burntMultiplier,
        thirst = thirst * burntMultiplier,
        calories = currentNutrient("calories") * burntMultiplier,
        carbohydrates = profile.carbohydrates ~= nil
            and currentNutrient("carbohydrates") * burntMultiplier or nil,
        proteins = profile.proteins ~= nil
            and currentNutrient("proteins") * burntMultiplier or nil,
        lipids = profile.lipids ~= nil
            and currentNutrient("lipids") * burntMultiplier or nil,
        negativeThirst = negativeThirst * burntMultiplier,
        fluidAmount = fluidAmount,
        fluidType = fluidType ~= "" and fluidType or nil,
        fluidHydration = fluidHydration,
        hydrationYieldPerLiter = H.Number(
            profile.hydrationYieldPerLiter, 0.50) or 0.50,
        fluidSafe = fluidSafe,
        useDelta = useDelta,
        remainingUses = remainingUses,
        food = profile.food == true,
        hydration = profile.hydration == true and fluidSafe
            and remainingUses > 0
            and (state.fluidAmount == nil
                or H.Number(state.fluidAmount, 0) > 0.000001),
        bandage = profile.bandage == true,
        unsafe = unsafe,
        burnt = state.burnt == true,
        burntMultiplier = burntMultiplier,
        effectiveValues = true,
        remainingFraction = remainingFraction,
        replaceOnUse = profile.replaceOnUse,
        replaceOnDeplete = profile.replaceOnDeplete,
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
    if spec.uses ~= nil then state.usedDelta = spec.uses end
    return H.Describe(Utility.GetStatic(typeID), state, record[C.QUANTITY])
end

function Utility.DescribeNPCItem(item)
    if type(item) ~= "table" then return nil end
    local typeID = CoreInventory.getItemTypeId(item.type, false)
    if not typeID then return nil end
    local state = type(item.itemState) == "table" and item.itemState or {}
    local merged = {}
    for key, value in pairs(state) do merged[key] = value end
    if item.uses ~= nil then merged.usedDelta = item.uses end
    return H.Describe(Utility.GetStatic(typeID, item.type), merged, item.stack)
end

function Utility.Supports(descriptor, request)
    if not descriptor or descriptor.unsafe then return false end
    if request.resourceKind == "FOOD" then
        return descriptor.food and descriptor.hunger > 0
    end
    if request.resourceKind == "HYDRATION" then
        return descriptor.hydration and descriptor.thirst > 0
            and descriptor.fluidSafe ~= false
    end
    if request.resourceKind == "MEDICAL" then
        return request.treatment == "BANDAGE" and descriptor.bandage == true
    end
    return false
end

return Utility
