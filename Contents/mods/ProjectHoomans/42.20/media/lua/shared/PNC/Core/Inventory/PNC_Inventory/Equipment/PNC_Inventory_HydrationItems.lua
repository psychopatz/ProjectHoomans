-- Normalize persisted item rows before inventory structure repair.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}
PNC.Inventory.Internal = PNC.Inventory.Internal or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal

local function normalizeInventoryItem(itemID, item)
    if type(item) ~= "table" then
        return nil, false, true
    end
    local normalizedType = Internal.normalizeItemType(item.type)
    if not normalizedType then
        return nil, false, true
    end
    item.id = Internal.normalizeString(item.id) or tostring(itemID)
    item.type = normalizedType
    item.container = Internal.normalizeString(item.container) or "root"
    item.stack = math.max(1, math.floor(tonumber(item.stack) or 1))
    item.uses = tonumber(item.uses)
    item.cond = tonumber(item.cond)
    item.ammoCount = item.ammoCount ~= nil
        and math.max(0, math.floor(tonumber(item.ammoCount) or 0))
        or nil
    item.fav = item.fav == true
    item.interactionLocked = item.interactionLocked == true
    item.interactionLockReason = Internal.normalizeString(
        item.interactionLockReason
    )
    item.templateKey = Internal.normalizeString(item.templateKey)
    item.wornSlot = Internal.normalizeString(item.wornSlot)
    item.attachedSlot = Internal.normalizeString(item.attachedSlot)
    item.equipSlot = Internal.normalizeString(item.equipSlot)
    item.customName = Internal.normalizeString(item.customName)
    item.identityNPCId = Internal.normalizeString(item.identityNPCId)
    item.identityNPCName = Internal.normalizeString(item.identityNPCName)
    if item.templateKey == "tmpl:identity_card:0"
        or item.identityNPCId ~= nil
    then
        item.interactionLocked = true
        item.interactionLockReason = "identity_card"
    end
    item.bagContainer = Internal.normalizeString(item.bagContainer)
    item.maxWeight = tonumber(item.maxWeight)
    local profile = Internal.getContainerProfile(item.type)
    item.weightReduction = item.weightReduction ~= nil
        and math.max(0, math.min(1,
            (tonumber(item.weightReduction) or 0) > 1
                and (tonumber(item.weightReduction) or 0) / 100
                or (tonumber(item.weightReduction) or 0)))
        or profile.weightReduction
    item.wearableSlot = Internal.normalizeString(item.wearableSlot)
        or profile.wearableSlot
    if (not item.maxWeight or item.maxWeight <= 0) and profile.capacity > 0 then
        item.maxWeight = profile.capacity
        item.bagContainer = item.bagContainer or ("bag_" .. tostring(item.id))
    end
    local stateChanged = Inventory.NormalizeItemState
        and Inventory.NormalizeItemState(item) or false
    return item.id, stateChanged, false
end

function Internal.normalizeHydrationItems(inv, rawItems, collectAuditStats)
    local items = {}
    local stateChanged = false
    local structureChanged = false
    local itemCountBefore = collectAuditStats and 0 or nil
    for itemID, item in pairs(rawItems) do
        if collectAuditStats then itemCountBefore = itemCountBefore + 1 end
        local normalizedID, itemStateChanged, invalid = normalizeInventoryItem(
            itemID,
            item
        )
        if invalid then
            structureChanged = true
        elseif normalizedID then
            if items[normalizedID] then structureChanged = true end
            items[normalizedID] = item
            if itemStateChanged then stateChanged = true end
        end
    end
    inv.items = items
    return stateChanged, structureChanged, itemCountBefore
end
