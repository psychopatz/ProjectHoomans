-- PNC inventory item construction, metadata lookup, and carry caches.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local ITEM_WEIGHT_CACHE = {}
local ITEM_CAPACITY_CACHE = {}

function Internal.getItemWeight(fullType)
    local cached = ITEM_WEIGHT_CACHE[fullType]
    local item
    if cached ~= nil then return cached end
    cached = 0.1
    if PNC.Equipment and PNC.Equipment.CreateItem then
        item = PNC.Equipment.CreateItem(fullType)
        if type(item) == "table" then item = item[1] end
    end
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
    local item
    if cached ~= nil then return cached end
    cached = 0
    if PNC.Equipment and PNC.Equipment.CreateItem then
        item = PNC.Equipment.CreateItem(fullType)
        if type(item) == "table" then item = item[1] end
    end
    if item and item.getMaxCapacity then
        cached = tonumber(item:getMaxCapacity()) or cached
    elseif item and item.getCapacity then
        cached = tonumber(item:getCapacity()) or cached
    elseif getScriptManager and getScriptManager().getItem then
        item = getScriptManager():getItem(fullType)
        if item and item.getCapacity then cached = tonumber(item:getCapacity()) or cached end
    end
    ITEM_CAPACITY_CACHE[fullType] = math.max(0, cached)
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
        fav = item.fav == true or nil,
        container = item.container,
        bagContainer = item.bagContainer,
        maxWeight = tonumber(item.maxWeight) or nil,
        templateKey = item.templateKey,
        preferredContainer = item.preferredContainer,
        wornSlot = item.wornSlot,
        attachedSlot = item.attachedSlot,
        equipSlot = item.equipSlot,
    }
end

function Internal.createItem(record, inv, spec)
    local itemID = Internal.normalizeString(spec.id) or Internal.nextItemID(record)
    local item = {
        id = itemID,
        type = Internal.normalizeString(spec.type),
        stack = math.max(1, math.floor(tonumber(spec.stack) or tonumber(spec.uses) or 1)),
        uses = tonumber(spec.uses),
        cond = tonumber(spec.cond),
        fav = spec.fav == true,
        container = Internal.normalizeString(spec.container) or "root",
        bagContainer = Internal.normalizeString(spec.bagContainer),
        maxWeight = tonumber(spec.maxWeight),
        templateKey = Internal.normalizeString(spec.templateKey),
        legacyTemplateKey = Internal.normalizeString(spec.legacyTemplateKey),
        preferredContainer = Internal.normalizeString(spec.preferredContainer),
        wornSlot = Internal.normalizeString(spec.wornSlot),
        attachedSlot = Internal.normalizeString(spec.attachedSlot),
        equipSlot = Internal.normalizeString(spec.equipSlot),
    }
    if not item.type then return nil end
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

function Internal.calculateWeights(inv)
    local usedWeight = 0
    local maxWeight = tonumber(inv.rootMaxWeight) or tonumber(inv.maxWeight) or 0
    local item
    for _, item in pairs(inv.items) do
        usedWeight = usedWeight
            + (Internal.getItemWeight(item.type) * math.max(1, tonumber(item.stack) or 1))
        if item.bagContainer and inv.containers[item.bagContainer] then
            maxWeight = maxWeight
                + math.max(0, tonumber(inv.containers[item.bagContainer].maxWeight) or 0)
        end
    end
    inv.cachedWeight = usedWeight
    inv.maxWeight = maxWeight
    return usedWeight, maxWeight
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
