if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Utility = PNC.ItemUtility
local H = Utility.Internal
local CoreInventory = H.CoreInventory
local C = H.Constants
local StateCodec = H.StateCodec

function H.Describe(profile, state, quantity)
    if not profile then return nil end
    state = type(state) == "table" and state or {}
    local usedDelta = H.Number(state.usedDelta, H.Number(state.uses))
    local useDelta = H.Number(profile.useDelta, 0) or 0
    local remainingUses = useDelta > 0 and math.max(0,
        math.floor((usedDelta or 1) / useDelta + 0.0001)) or 1
    local age = H.Number(state.age, 0) or 0
    local unsafe = state.rotten == true or state.poisoned == true
        or H.Number(state.poisonPower, 0) > 0
    if profile.offAgeMax and profile.offAgeMax > 0
        and age >= profile.offAgeMax
    then
        unsafe = true
    end
    local expiry = 0
    if profile.offAgeMax and profile.offAgeMax > 0 then
        expiry = math.max(0, math.min(1, age / profile.offAgeMax))
    end
    return {
        typeId = profile.typeId,
        fullType = profile.fullType,
        quantity = math.max(1, math.floor(H.Number(quantity, 1) or 1)),
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
    return H.Describe(Utility.GetStatic(typeID), state, record[C.QUANTITY])
end

function Utility.DescribeNPCItem(item)
    if type(item) ~= "table" then return nil end
    local typeID = CoreInventory.getItemTypeId(item.type, false)
    if not typeID then return nil end
    local state = type(item.itemState) == "table" and item.itemState or {}
    local merged = {}
    for key, value in pairs(state) do merged[key] = value end
    merged.usedDelta = item.uses
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
