-- PNC inventory item construction, metadata lookup, and carry caches.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local ITEM_WEIGHT_CACHE = {}
local ITEM_CAPACITY_CACHE = {}
local ITEM_CONTAINER_PROFILE_CACHE = {}
local ITEM_STATE_SCALAR_FIELDS = {
    "condition",
    "headCondition",
    "quality",
    "haveBeenRepaired",
    "usedDelta",
    "favorite",
    "customName",
    "ammoCount",
    "fluidAmount",
    "fluidType",
    "visualBaseTexture",
    "visualTextureChoice",
    "visualDecal",
    "visualTintR",
    "visualTintG",
    "visualTintB",
    "visualFullType",
}

local function boundedString(value)
    local limit
    local output
    if value == nil then return nil end
    output = tostring(value)
    limit = tonumber(PNC.Const
        and PNC.Const.INVENTORY_ITEM_STATE_MAX_STRING_LENGTH) or 1024
    if #output > limit then
        output = string.sub(output, 1, limit)
    end
    return output
end

local function sanitizeScalar(value)
    local kind = type(value)
    if kind == "string" then return boundedString(value) end
    if kind == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return nil
        end
        return value
    end
    if kind == "boolean" then return value end
    return nil
end

function Internal.sanitizeItemState(raw)
    local output = {}
    local field
    local value
    local entries = {}
    local entry
    local key
    local copied = 0
    local maxKeys = tonumber(PNC.Const
        and PNC.Const.INVENTORY_ITEM_STATE_MAX_MODDATA_KEYS) or 64
    if type(raw) ~= "table" then return output end
    for i = 1, #ITEM_STATE_SCALAR_FIELDS do
        field = ITEM_STATE_SCALAR_FIELDS[i]
        value = sanitizeScalar(raw[field])
        if value ~= nil then output[field] = value end
    end
    if type(raw.modData) == "table" then
        for key, value in pairs(raw.modData) do
            entries[#entries + 1] = {
                key = tostring(key),
                value = value,
            }
        end
        table.sort(entries, function(left, right)
            return left.key < right.key
        end)
        output.modData = {}
        for i = 1, #entries do
            if copied >= maxKeys then break end
            entry = entries[i]
            key = entry.key
            value = sanitizeScalar(entry.value)
            if value ~= nil then
                output.modData[boundedString(key)] = value
                copied = copied + 1
            end
        end
        if copied <= 0 then output.modData = nil end
    end
    return output
end

function Inventory.SanitizeItemState(raw)
    return Internal.sanitizeItemState(raw)
end

local function normalizeReduction(value)
    value = tonumber(value) or 0
    if value > 1 then value = value / 100 end
    return math.max(0, math.min(1, value))
end

local function createProbe(fullType)
    local item
    if PNC.Equipment and PNC.Equipment.CreateItem then
        item = PNC.Equipment.CreateItem(fullType)
        if type(item) == "table" and not item.getActualWeight and item[1] then
            item = item[1]
        end
    end
    return item
end

function Internal.getContainerProfile(fullType)
    local cached = ITEM_CONTAINER_PROFILE_CACHE[fullType]
    local item
    local scriptItem
    local capacity = 0
    local reduction = 0
    local wearableSlot
    if cached ~= nil then return cached end

    item = createProbe(fullType)
    if item and item.getMaxCapacity then
        capacity = tonumber(item:getMaxCapacity()) or capacity
    elseif item and item.getCapacity then
        capacity = tonumber(item:getCapacity()) or capacity
    end
    if item and item.getWeightReduction then
        reduction = normalizeReduction(item:getWeightReduction())
    end
    if item and item.canBeEquipped then
        wearableSlot = Internal.normalizeString(item:canBeEquipped())
    end

    if getScriptManager and getScriptManager().getItem then
        scriptItem = getScriptManager():getItem(fullType)
        if capacity <= 0 and scriptItem and scriptItem.getCapacity then
            capacity = tonumber(scriptItem:getCapacity()) or capacity
        end
        if reduction <= 0 and scriptItem and scriptItem.getWeightReduction then
            reduction = normalizeReduction(scriptItem:getWeightReduction())
        end
        if not wearableSlot and scriptItem and scriptItem.getCanBeEquipped then
            wearableSlot = Internal.normalizeString(scriptItem:getCanBeEquipped())
        end
    end

    cached = {
        capacity = math.max(0, capacity),
        weightReduction = reduction,
        wearableSlot = wearableSlot,
    }
    ITEM_CONTAINER_PROFILE_CACHE[fullType] = cached
    return cached
end

function Inventory.GetContainerProfile(fullType)
    local profile = Internal.getContainerProfile(fullType)
    return {
        capacity = profile.capacity,
        weightReduction = profile.weightReduction,
        wearableSlot = profile.wearableSlot,
    }
end

function Internal.getItemWeight(fullType)
    local cached = ITEM_WEIGHT_CACHE[fullType]
    local item
    if cached ~= nil then return cached end
    cached = 0.1
    item = createProbe(fullType)
    if item and item.getActualWeight then
        cached = tonumber(item:getActualWeight()) or cached
    elseif item and item.getWeight then
        cached = tonumber(item:getWeight()) or cached
    elseif getScriptManager and getScriptManager().getItem then
        item = getScriptManager():getItem(fullType)
        if item and item.getActualWeight then
            cached = tonumber(item:getActualWeight()) or cached
        elseif item and item.getWeight then
            cached = tonumber(item:getWeight()) or cached
        end
    end
    ITEM_WEIGHT_CACHE[fullType] = math.max(0, cached)
    return ITEM_WEIGHT_CACHE[fullType]
end

function Internal.getItemCapacity(fullType)
    local cached = ITEM_CAPACITY_CACHE[fullType]
    if cached ~= nil then return cached end
    ITEM_CAPACITY_CACHE[fullType] = Internal.getContainerProfile(fullType).capacity
    return ITEM_CAPACITY_CACHE[fullType]
end

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

-- Persistence omits values that can be reconstructed from the script item.
-- Network payloads keep using itemToPayload because clients need a complete
-- standalone description.
function Internal.itemToPersistencePayload(item)
    local profile
    local output
    local itemState
    if not item or not item.id or not item.type then return nil end
    profile = Internal.getContainerProfile(item.type)
    itemState = Internal.sanitizeItemState(item.itemState)
    if item.cond ~= nil then itemState.condition = nil end
    if item.uses ~= nil then itemState.usedDelta = nil end
    if item.ammoCount ~= nil then itemState.ammoCount = nil end
    if item.fav ~= nil then itemState.favorite = nil end
    if item.customName ~= nil then itemState.customName = nil end
    if Internal.countMapEntries(itemState) <= 0 then itemState = nil end
    output = {
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
        maxWeight = tonumber(item.maxWeight) ~= tonumber(profile.capacity)
            and tonumber(item.maxWeight) or nil,
        weightReduction = tonumber(item.weightReduction)
                ~= tonumber(profile.weightReduction)
            and tonumber(item.weightReduction) or nil,
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
        itemState = itemState,
    }
    return output
end

function Internal.createItem(record, inv, spec)
    local itemID = Internal.normalizeString(spec.id) or Internal.nextItemID(record)
    local fullType = Internal.normalizeString(spec.type)
    local profile
    if not fullType then return nil end
    profile = Internal.getContainerProfile(fullType)
    local item = {
        id = itemID,
        type = fullType,
        stack = math.max(1, math.floor(tonumber(spec.stack) or tonumber(spec.uses) or 1)),
        uses = tonumber(spec.uses),
        cond = tonumber(spec.cond),
        ammoCount = spec.ammoCount ~= nil
            and math.max(0, math.floor(tonumber(spec.ammoCount) or 0))
            or nil,
        fav = spec.fav == true,
        interactionLocked = spec.interactionLocked == true,
        interactionLockReason = Internal.normalizeString(
            spec.interactionLockReason
        ),
        container = Internal.normalizeString(spec.container) or "root",
        bagContainer = Internal.normalizeString(spec.bagContainer),
        maxWeight = tonumber(spec.maxWeight)
            or (profile.capacity > 0 and profile.capacity or nil),
        weightReduction = spec.weightReduction ~= nil
            and normalizeReduction(spec.weightReduction)
            or profile.weightReduction,
        wearableSlot = Internal.normalizeString(spec.wearableSlot)
            or profile.wearableSlot,
        templateKey = Internal.normalizeString(spec.templateKey),
        legacyTemplateKey = Internal.normalizeString(spec.legacyTemplateKey),
        preferredContainer = Internal.normalizeString(spec.preferredContainer),
        wornSlot = Internal.normalizeString(spec.wornSlot),
        attachedSlot = Internal.normalizeString(spec.attachedSlot),
        equipSlot = Internal.normalizeString(spec.equipSlot),
        customName = Internal.normalizeString(spec.customName),
        identityNPCId = Internal.normalizeString(spec.identityNPCId),
        identityNPCName = Internal.normalizeString(spec.identityNPCName),
        itemState = Internal.sanitizeItemState(spec.itemState),
    }
    inv.items[itemID] = item
    Internal.addItemToContainer(inv, itemID, item.container)
    if item.maxWeight and item.maxWeight > 0 then
        Internal.ensureContainer(inv, "bag_" .. tostring(itemID), item.maxWeight)
        item.bagContainer = "bag_" .. tostring(itemID)
    elseif item.bagContainer then
        Internal.ensureContainer(inv, item.bagContainer, 0)
    end
    if item.wornSlot then inv.worn[item.wornSlot] = itemID end
    if item.attachedSlot then inv.attached[item.attachedSlot] = itemID end
    if item.equipSlot == "primary" then
        inv.equipped.primary = itemID
    elseif item.equipSlot == "secondary" then
        inv.equipped.secondary = itemID
    elseif item.equipSlot == "bag" then
        inv.equipped.bag = itemID
    end
    return item
end

function Internal.normalizeLegacyBagSlot(inv)
    local itemID = inv and inv.equipped and inv.equipped.bag or nil
    local item = itemID and inv.items and inv.items[itemID] or nil
    local slot
    if not item then
        if inv and inv.equipped then inv.equipped.bag = nil end
        return false
    end
    slot = Internal.normalizeString(item.wearableSlot)
        or Internal.getContainerProfile(item.type).wearableSlot
    item.equipSlot = nil
    inv.equipped.bag = nil
    if slot and (not inv.worn[slot] or inv.worn[slot] == item.id) then
        item.wearableSlot = slot
        item.wornSlot = slot
        inv.worn[slot] = item.id
        return true
    end
    return false
end

function Internal.ensureIdentityCard(record, inv)
    local item
    local displayName
    if not record or not inv or type(inv.items) ~= "table" then return nil end
    item = Internal.findItemByTemplateKey(inv, "tmpl:identity_card:0")
    displayName = tostring(record.name or record.displayName or "Unknown NPC")
    if not item then
        item = Internal.createItem(record, inv, {
            type = "Base.IDcard",
            container = "root",
            templateKey = "tmpl:identity_card:0",
        })
    end
    if item then
        -- Repair the incorrectly-cased type written by generator revision 3.
        -- Script item IDs are case-sensitive in Build 42.
        item.type = "Base.IDcard"
        item.customName = "ID Card: " .. displayName
        item.identityNPCId = tostring(record.id)
        item.identityNPCName = displayName
        item.interactionLocked = true
        item.interactionLockReason = "identity_card"
    end
    return item
end

function Internal.calculateWeights(inv)
    local usedWeight = 0
    local maxWeight = tonumber(inv.rootMaxWeight) or tonumber(inv.maxWeight) or 0
    local ownerByContainer = {}
    local reductionByContainer = { root = 0 }
    local item
    local function resolveContainerReduction(containerID, depth)
        local cached = reductionByContainer[containerID]
        local owner
        local reduction
        if cached ~= nil then return cached end
        if depth > 12 then return 0 end
        owner = ownerByContainer[containerID]
        if not owner then
            reductionByContainer[containerID] = 0
            return 0
        end
        if owner.wornSlot and inv.worn[owner.wornSlot] == owner.id then
            reduction = normalizeReduction(owner.weightReduction)
        else
            reduction = resolveContainerReduction(owner.container or "root", depth + 1)
        end
        reductionByContainer[containerID] = reduction
        return reduction
    end

    for _, item in pairs(inv.items) do
        if item.bagContainer then ownerByContainer[item.bagContainer] = item end
    end
    for _, item in pairs(inv.items) do
        local itemWeight = Internal.getItemWeight(item.type)
            * math.max(1, tonumber(item.stack) or 1)
        local reduction = resolveContainerReduction(item.container or "root", 0)
        usedWeight = usedWeight
            + (itemWeight * (1 - reduction))
    end
    inv.cachedWeight = usedWeight
    inv.maxWeight = maxWeight
    return usedWeight, maxWeight
end

function Internal.getContainerRawWeight(inv, containerID)
    local container = inv and inv.containers and inv.containers[containerID] or nil
    local usedWeight = 0
    local item
    local i
    if not container then return nil end
    for i = 1, #(container.items or {}) do
        item = inv.items and inv.items[container.items[i]] or nil
        if item then
            usedWeight = usedWeight + (Internal.getItemWeight(item.type)
                * math.max(1, tonumber(item.stack) or 1))
        end
    end
    return usedWeight
end

function Inventory.GetEncumbranceState(record)
    local inv = Inventory.EnsureRecordInventory(record)
    local usedWeight
    local maxWeight
    local ratio
    local level
    local staminaMultiplier
    local drainMultiplier
    local recoveryMultiplier
    if not inv then return nil end
    usedWeight = tonumber(inv.cachedWeight) or 0
    maxWeight = math.max(1, tonumber(inv.maxWeight) or 1)
    ratio = usedWeight / maxWeight
    if ratio >= 1.75 then
        level = "severe"
        staminaMultiplier = 0.40
        drainMultiplier = 2.8
        recoveryMultiplier = 0.20
    elseif ratio >= 1.50 then
        level = "very_heavy"
        staminaMultiplier = 0.55
        drainMultiplier = 2.3
        recoveryMultiplier = 0.40
    elseif ratio >= 1.25 then
        level = "heavy"
        staminaMultiplier = 0.75
        drainMultiplier = 1.9
        recoveryMultiplier = 0.65
    elseif ratio > 1.0 then
        level = "encumbered"
        staminaMultiplier = 0.90
        drainMultiplier = 1.5
        recoveryMultiplier = 0.85
    else
        level = "normal"
        staminaMultiplier = 1.0
        drainMultiplier = 1.0
        recoveryMultiplier = 1.0
    end
    return {
        usedWeight = usedWeight,
        maxWeight = maxWeight,
        ratio = ratio,
        level = level,
        staminaMultiplier = staminaMultiplier,
        drainMultiplier = drainMultiplier,
        recoveryMultiplier = recoveryMultiplier,
        severe = ratio >= 1.75,
    }
end

function Internal.findItemByTemplateKey(inv, templateKey)
    local item
    if not inv or not templateKey then return nil end
    for _, item in pairs(inv.items or {}) do
        if item and (item.templateKey == templateKey or item.legacyTemplateKey == templateKey) then
            return item
        end
    end
    return nil
end

function Inventory.RebuildCaches(record)
    local inv
    if not record or type(record.inventory) ~= "table" then return nil end
    inv = record.inventory
    inv.rootMaxWeight = Internal.buildBaseCarryWeight(record)
    Internal.ensureContainer(inv, "root", inv.rootMaxWeight)
    inv.containers.root.maxWeight = inv.rootMaxWeight
    Internal.calculateWeights(inv)
    inv.itemCount = Internal.countMapEntries(inv.items)
    inv.containerCount = Internal.countMapEntries(inv.containers)
    inv.remainingWeight = math.max(0,
        (tonumber(inv.maxWeight) or 0) - (tonumber(inv.cachedWeight) or 0))
    inv.signature = table.concat({
        tostring(inv.revision or 0),
        tostring(inv.itemCount or 0),
        tostring(math.floor((tonumber(inv.cachedWeight) or 0) * 10)),
        tostring(record.equipment and record.equipment.primaryFullType or ""),
        tostring(record.equipment and record.equipment.secondaryFullType or ""),
    }, ":")
    return inv
end
