-- PNC inventory synchronization with the legacy equipment representation.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal

function Inventory.SyncEquipmentFromInventory(record)
    local inv
    local function fullTypeFor(itemID)
        local item = inv and inv.items and inv.items[itemID] or nil
        return item and item.type or nil
    end
    local slot
    if not record then return nil end
    inv = record.inventory
    if not inv then return nil end
    record.equipment = PNC.Equipment
        and PNC.Equipment.NormalizeLoadoutSpec
        and PNC.Equipment.NormalizeLoadoutSpec(record.equipment)
        or (record.equipment or {
            primaryFullType = nil,
            secondaryFullType = nil,
            worn = {},
            attached = {},
        })
    record.equipment.primaryFullType = fullTypeFor(inv.equipped.primary)
    record.equipment.secondaryFullType = fullTypeFor(inv.equipped.secondary)
    record.equipment.worn = {}
    record.equipment.attached = {}
    for slot, _ in pairs(inv.worn or {}) do
        record.equipment.worn[slot] = fullTypeFor(inv.worn[slot])
    end
    for slot, _ in pairs(inv.attached or {}) do
        record.equipment.attached[slot] = fullTypeFor(inv.attached[slot])
    end
    return record.equipment
end

function Inventory.SyncFromEquipment(record, reason)
    local inv
    local equipment
    local hadInventory
    local preserved = {}
    local previousInv
    local function assignItem(slotType, slotValue, fullType)
        local item
        if not fullType then return end
        if slotType == "equip" and slotValue == "bag" then
            item = Internal.createItem(record, inv, {
                type = fullType,
                container = "root",
                equipSlot = "bag",
                maxWeight = Internal.getItemCapacity(fullType),
            })
            return item and item.id or nil
        end
        item = Internal.createItem(record, inv, {
            type = fullType,
            container = "root",
            wornSlot = slotType == "worn" and slotValue or nil,
            attachedSlot = slotType == "attached" and slotValue or nil,
            equipSlot = slotType == "equip" and slotValue or nil,
        })
        return item and item.id or nil
    end
    local key
    if not record then return nil end

    hadInventory = type(record.inventory) == "table" and record.inventory.revision ~= nil
    previousInv = hadInventory and record.inventory or nil
    if previousInv and type(previousInv.items) == "table" then
        local item
        for _, item in pairs(previousInv.items) do
            if type(item) == "table" and not item.wornSlot and not item.attachedSlot and not item.equipSlot then
                preserved[#preserved + 1] = Internal.itemToPayload(item)
            end
        end
    end

    inv = Internal.createBaseInventory(record)
    record.inventory = inv
    equipment = PNC.Equipment
        and PNC.Equipment.EnsureRecordEquipment
        and PNC.Equipment.EnsureRecordEquipment(record)
        or record.equipment
    if equipment.attached
        and equipment.attached.Back
        and not equipment.primaryFullType
        and Internal.getItemCapacity(equipment.attached.Back) > 0
    then
        assignItem("equip", "bag", equipment.attached.Back)
    end
    if equipment.primaryFullType then assignItem("equip", "primary", equipment.primaryFullType) end
    if equipment.secondaryFullType then assignItem("equip", "secondary", equipment.secondaryFullType) end
    for key, _ in pairs(equipment.worn or {}) do
        assignItem("worn", key, equipment.worn[key])
    end
    for key, _ in pairs(equipment.attached or {}) do
        assignItem("attached", key, equipment.attached[key])
    end
    for key = 1, #preserved do
        local item = preserved[key]
        if item then
            if item.container ~= "root" and not inv.containers[item.container] then
                if item.preferredContainer == "bag" and inv.equipped.bag and inv.items[inv.equipped.bag] then
                    item.container = inv.items[inv.equipped.bag].bagContainer or "root"
                else
                    item.container = "root"
                end
            end
            Internal.createItem(record, inv, item)
        end
    end
    inv.deltaMode = "template_plus_delta"
    if hadInventory then inv.revision = math.max(1, tonumber(inv.revision) or 0) end
    Internal.refreshNextItemSerial(record, inv)
    Inventory.RebuildCaches(record)
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "inventory")
    end
    return record.inventory
end
