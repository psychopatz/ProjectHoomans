if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Utility = PNC.ItemUtility
local H = Utility.Internal
local CoreInventory = H.CoreInventory
local C = H.Constants
local StateCodec = H.StateCodec
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"

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

local function currentFoodValues(profile, state, status)
    local hungerChange = H.Number(state.hungChange)
    local thirstChange = H.Number(state.thirstChange)
    local hunger = profile.hunger
    local thirst = profile.thirst
    local negativeThirst = profile.negativeThirst
    if hungerChange ~= nil then
        if state.cooked == true then
            hungerChange = hungerChange * 1.3
        elseif state.burnt == true then
            hungerChange = hungerChange / 3
        elseif status.rotten then
            hungerChange = hungerChange / 2.2
        elseif status.stale then
            hungerChange = hungerChange / 1.3
        end
        hunger = math.max(0, -hungerChange)
    end
    if thirstChange ~= nil then
        if state.burnt == true then
            thirstChange = thirstChange / 5
        elseif state.cooked == true then
            thirstChange = thirstChange / 2
        end
        thirst = math.max(0, -thirstChange)
        negativeThirst = math.max(0, thirstChange)
    end
    return hunger, thirst, negativeThirst
end

function H.Describe(profile, state, quantity)
    if not profile then return nil end
    state = effectiveState(profile, state)
    local usedDelta = H.Number(state.usedDelta, H.Number(state.uses))
    local useDelta = H.Number(profile.useDelta, 0) or 0
    local remainingUses = useDelta > 0 and math.max(0,
        math.floor((usedDelta or 1) / useDelta + 0.0001)) or 1
    local age = H.Number(state.age, 0) or 0
    local foodStatus = Portable.GetFoodStatus(state, profile)
    local hunger
    local thirst
    local negativeThirst
    hunger, thirst, negativeThirst = currentFoodValues(
        profile, state, foodStatus
    )
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
    return {
        typeId = profile.typeId,
        fullType = profile.fullType,
        quantity = math.max(1, math.floor(H.Number(quantity, 1) or 1)),
        hunger = hunger,
        thirst = thirst,
        calories = profile.calories,
        negativeThirst = negativeThirst,
        useDelta = useDelta,
        remainingUses = remainingUses,
        food = profile.food == true,
        hydration = profile.hydration == true and remainingUses > 0
            and (state.fluidAmount == nil
                or H.Number(state.fluidAmount, 0) > 0.000001),
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
    end
    if request.resourceKind == "MEDICAL" then
        return request.treatment == "BANDAGE" and descriptor.bandage == true
    end
    return false
end

return Utility
