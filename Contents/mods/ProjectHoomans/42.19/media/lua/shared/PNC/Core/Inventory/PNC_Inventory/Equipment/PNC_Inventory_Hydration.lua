-- PNC inventory record hydration and normalization.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal

function Inventory.EnsureRecordInventory(record)
    local inv
    local raw
    local itemID
    local item
    if not record then return nil end
    if type(record.inventory) ~= "table" and type(record.persistedInventory) == "table" then
        local persisted = record.persistedInventory
        local persistedGenerator = persisted.template and tonumber(persisted.template.generatorVersion) or nil
        local currentGenerator = PNC.Const and tonumber(PNC.Const.GENERATOR_VERSION) or 1
        record.persistedInventory = nil
        local hydrated = Inventory.Deserialize(record, persisted)
        if persistedGenerator ~= currentGenerator and PNC.Registry and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(record, "inventory_rebase")
        end
        return hydrated
    end
    if type(record.inventory) ~= "table" and record.legacyEquipmentInventory == true then
        record.legacyEquipmentInventory = nil
        return Inventory.SyncFromEquipment(record, "legacy_equipment_load")
    end
    if type(record.inventory) ~= "table" or not record.inventory.items or not record.inventory.containers then
        return Inventory.CreateFromTemplate(record)
    end

    inv = record.inventory
    inv.revision = math.max(0, math.floor(tonumber(inv.revision) or 0))
    inv.deltaMode = "template_plus_delta"
    inv.cachedWeight = tonumber(inv.cachedWeight) or 0
    inv.rootMaxWeight = tonumber(inv.rootMaxWeight)
        or tonumber(inv.maxWeight)
        or Internal.buildBaseCarryWeight(record)
    inv.maxWeight = tonumber(inv.maxWeight) or inv.rootMaxWeight
    inv.equipped = type(inv.equipped) == "table"
        and inv.equipped
        or { primary = nil, secondary = nil, bag = nil }
    inv.worn = type(inv.worn) == "table" and inv.worn or {}
    inv.attached = type(inv.attached) == "table" and inv.attached or {}
    inv.items = type(inv.items) == "table" and inv.items or {}
    inv.containers = type(inv.containers) == "table" and inv.containers or {}
    Internal.ensureContainer(inv, "root", inv.rootMaxWeight)

    raw = inv.items
    inv.items = {}
    for itemID, item in pairs(raw) do
        if type(item) == "table" and Internal.normalizeString(item.type) then
            item.id = Internal.normalizeString(item.id) or tostring(itemID)
            item.type = Internal.normalizeString(item.type)
            item.container = Internal.normalizeString(item.container) or "root"
            item.stack = math.max(1, math.floor(tonumber(item.stack) or tonumber(item.uses) or 1))
            item.uses = tonumber(item.uses)
            item.cond = tonumber(item.cond)
            item.templateKey = Internal.normalizeString(item.templateKey)
            item.wornSlot = Internal.normalizeString(item.wornSlot)
            item.attachedSlot = Internal.normalizeString(item.attachedSlot)
            item.equipSlot = Internal.normalizeString(item.equipSlot)
            item.bagContainer = Internal.normalizeString(item.bagContainer)
            item.maxWeight = tonumber(item.maxWeight)
            inv.items[item.id] = item
            Internal.ensureContainer(inv, item.container,
                item.container == "root" and inv.rootMaxWeight or 0)
            Internal.addItemToContainer(inv, item.id, item.container)
            if item.bagContainer then
                Internal.ensureContainer(inv, item.bagContainer, tonumber(item.maxWeight) or 0)
            end
        end
    end
    Internal.getRuntimeState(record)
    Internal.refreshNextItemSerial(record, inv)
    Inventory.SyncEquipmentFromInventory(record)
    Inventory.RebuildCaches(record)
    return record.inventory
end

function Inventory.GetWeightState(record)
    local inv = Inventory.EnsureRecordInventory(record)
    return inv and {
        usedWeight = tonumber(inv.cachedWeight) or 0,
        maxWeight = tonumber(inv.maxWeight) or 0,
        remainingWeight = tonumber(inv.remainingWeight)
            or math.max(0, (tonumber(inv.maxWeight) or 0) - (tonumber(inv.cachedWeight) or 0)),
    } or nil
end
