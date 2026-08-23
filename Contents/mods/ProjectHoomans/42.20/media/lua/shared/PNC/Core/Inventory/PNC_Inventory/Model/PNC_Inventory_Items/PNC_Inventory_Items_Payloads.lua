local Internal = PNC.Inventory.Internal

function Internal.itemToPayload(item)
    if not item or not item.id or not item.type then return nil end
    return {
        id = item.id,
        type = item.type,
        stack = tonumber(item.stack) or nil,
        uses = tonumber(item.uses) or nil,
        cond = tonumber(item.cond) or nil,
        ammoCount = tonumber(item.ammoCount),
        fav = item.fav == true or nil,
        interactionLocked = item.interactionLocked == true or nil,
        interactionLockReason = item.interactionLockReason,
        container = item.container,
        bagContainer = item.bagContainer,
        maxWeight = tonumber(item.maxWeight) or nil,
        weightReduction = tonumber(item.weightReduction) or nil,
        wearableSlot = item.wearableSlot,
        templateKey = item.templateKey,
        preferredContainer = item.preferredContainer,
        wornSlot = item.wornSlot,
        attachedSlot = item.attachedSlot,
        equipSlot = item.equipSlot,
        customName = item.customName,
        identityNPCId = item.identityNPCId,
        identityNPCName = item.identityNPCName,
        itemState = Internal.sanitizeItemState(item.itemState),
    }
end

local function persistentItemState(item)
    local itemState = Internal.sanitizeItemState(item.itemState)
    if item.cond ~= nil then itemState.condition = nil end
    if item.uses ~= nil then itemState.usedDelta = nil end
    if item.ammoCount ~= nil then itemState.ammoCount = nil end
    if item.fav ~= nil then itemState.favorite = nil end
    if item.customName ~= nil then itemState.customName = nil end
    if Internal.countMapEntries(itemState) <= 0 then return nil end
    return itemState
end

local function changedNumber(value, defaultValue)
    local number = tonumber(value)
    return number ~= tonumber(defaultValue) and number or nil
end

-- Persistence omits values reconstructable from the script item. Network
-- payloads remain complete standalone descriptions through itemToPayload.
function Internal.itemToPersistencePayload(item)
    local profile
    if not item or not item.id or not item.type then return nil end
    profile = Internal.getContainerProfile(item.type)
    return {
        id = item.id,
        type = item.type,
        stack = (tonumber(item.stack) or 1) ~= 1
            and math.max(1, math.floor(tonumber(item.stack) or 1)) or nil,
        uses = tonumber(item.uses),
        cond = tonumber(item.cond),
        ammoCount = tonumber(item.ammoCount),
        fav = item.fav == true or nil,
        interactionLocked = item.interactionLocked == true or nil,
        interactionLockReason = item.interactionLocked == true
            and item.interactionLockReason or nil,
        container = item.container ~= "root" and item.container or nil,
        maxWeight = changedNumber(item.maxWeight, profile.capacity),
        weightReduction = changedNumber(
            item.weightReduction,
            profile.weightReduction
        ),
        wearableSlot = item.wearableSlot ~= profile.wearableSlot
            and item.wearableSlot or nil,
        templateKey = item.templateKey,
        preferredContainer = item.preferredContainer,
        wornSlot = item.wornSlot,
        attachedSlot = item.attachedSlot,
        equipSlot = item.equipSlot,
        customName = item.customName,
        identityNPCId = item.identityNPCId,
        identityNPCName = item.identityNPCName,
        itemState = persistentItemState(item),
    }
end
